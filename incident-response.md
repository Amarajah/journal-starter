# Journal API — Incident Response

## Alert
- Alarm: JournalAPI-HighLatency
- Metric: http.server.duration
- Namespace: JournalAPI
- Threshold: Average latency > 500 ms
- Evaluation: 2 consecutive periods of 60 seconds
- Missing data: Not breaching

## Normal Baseline
- Average latency: approximately 24–25 ms
- Observed maximum: 72 ms

## Investigation Procedure
1. Check the CloudWatch alarm state.
2. Inspect HTTP duration metrics in the JournalAPI namespace.
3. Check API pod health:
   kubectl get pods -l app=journal-api
4. Inspect API logs:
   kubectl logs deployment/journal-api --since=15m
5. Inspect recent traces in AWS X-Ray.
6. Check database connectivity if requests are slow or failing.

## Recovery
1. Identify the cause of elevated latency.
2. Apply the appropriate fix.
3. Verify API health and response times.
4. Confirm the CloudWatch alarm returns to OK.

## Escalation
If latency remains elevated after investigation, review
application resource usage, database performance, and
network connectivity before making infrastructure changes.