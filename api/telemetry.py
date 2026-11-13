import logging
import os

from fastapi import FastAPI
from opentelemetry import metrics, trace
from opentelemetry._logs import set_logger_provider
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.extension.aws.trace import AwsXRayIdGenerator
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

LOG_FORMAT = (
    "%(asctime)s %(levelname)s [trace_id=%(otelTraceID)s span_id=%(otelSpanID)s] "
    "%(name)s: %(message)s"
)


class TraceFormatter(logging.Formatter):
    """Falls back to '-' when a record has no trace context."""

    def format(self, record: logging.LogRecord) -> str:
        record.otelTraceID = getattr(record, "otelTraceID", "-")
        record.otelSpanID = getattr(record, "otelSpanID", "-")
        return super().format(record)


def setup_telemetry(app: FastAPI) -> None:
    # Telemetry is off unless an endpoint is configured, so tests, CI and
    # plain local runs are unaffected.
    if not os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT"):
        return

    resource = Resource.create({"service.name": os.getenv("OTEL_SERVICE_NAME", "journal-api")})

    # Traces (task 2). AwsXRayIdGenerator makes trace IDs X-Ray accepts.
    tracer_provider = TracerProvider(resource=resource, id_generator=AwsXRayIdGenerator())
    tracer_provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter()))
    trace.set_tracer_provider(tracer_provider)

    # Metrics (task 3)
    reader = PeriodicExportingMetricReader(OTLPMetricExporter())
    metrics.set_meter_provider(MeterProvider(resource=resource, metric_readers=[reader]))

    # Logs correlated with traces (task 7)
    LoggingInstrumentor().instrument()  # adds otelTraceID / otelSpanID to records
    logger_provider = LoggerProvider(resource=resource)
    logger_provider.add_log_record_processor(BatchLogRecordProcessor(OTLPLogExporter()))
    set_logger_provider(logger_provider)

    root = logging.getLogger()
    root.setLevel(logging.INFO)
    console = logging.StreamHandler()
    console.setFormatter(TraceFormatter(LOG_FORMAT))
    root.addHandler(console)  # shows trace IDs in `kubectl logs`
    root.addHandler(LoggingHandler(level=logging.INFO, logger_provider=logger_provider))

    # Auto-instrument every route (task 4)
    FastAPIInstrumentor.instrument_app(app)
