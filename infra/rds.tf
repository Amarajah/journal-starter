resource "aws_db_subnet_group" "journal" {
  name       = "${var.cluster_name}-db"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-"
  description = "PostgreSQL access from EKS nodes only"
  vpc_id      = module.vpc.vpc_id
}

locals {
  rds_source_sgs = {
    node    = module.eks.node_security_group_id
    primary = module.eks.cluster_primary_security_group_id
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_nodes" {
  for_each = local.rds_source_sgs

  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = each.value
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from EKS (${each.key})"
}

resource "aws_db_instance" "journal" {
  identifier        = "${var.cluster_name}-db"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = "db.t4g.micro" # same class your current DB runs on, so the Free Plan allows it
  allocated_storage = 20
  storage_encrypted = true

  db_name  = "career_journal"
  username = "journal_admin"

  # AWS generates the password and keeps it in Secrets Manager, so it never appears in code or state files you commit
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.journal.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = false

  backup_retention_period = 1
  skip_final_snapshot     = true # so `terraform destroy` works at cleanup
  deletion_protection     = false
  apply_immediately       = true
}

output "db_host" {
  value = aws_db_instance.journal.address
}

output "db_secret_arn" {
  value = aws_db_instance.journal.master_user_secret[0].secret_arn
}