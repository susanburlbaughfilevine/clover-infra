locals {
  db_options = {
    sqlserver-se = {
      license_model = "license-included"
      export_logs   = ["agent", "error"]
      port          = 1433
    }
    postgres = {
      license_model = "postgresql-license"
      export_logs   = ["postgresql"]
      port          = 5432
    }
    mysql = {
      license_model = "general-public-license"
      export_logs   = ["audit", "error", "general", "slowquery"]
      port          = 1433
    }
  }
}

resource "aws_rds_cluster" "sqlserver" {
  cluster_identifier              = lower("${var.envName}-cloverdx")
  availability_zones              = ["us-west-2a", "us-west-2b", "us-west-2c"]
  engine                          = "aurora-postgresql"
  engine_mode                     = "serverless"
  master_username                 = var.rds_user_name
  master_password                 = var.rds_user_password
  backup_retention_period         = 35
  preferred_backup_window         = "07:00-08:00"
  vpc_security_group_ids          = [aws_security_group.dataaccess.id]
  storage_encrypted               = true
  kms_key_id                      = data.aws_kms_alias.default.target_key_arn
  enabled_cloudwatch_logs_exports = local.db_options[var.rds_engine].export_logs
  deletion_protection             = false
  db_subnet_group_name            = aws_db_subnet_group.sqlserver.name
  copy_tags_to_snapshot           = true
  preferred_maintenance_window    = "sun:09:00-sun:11:00"
}

resource "aws_db_subnet_group" "sqlserver" {
  name        = lower("${var.envName}-cloverdx-db-subnets")
  subnet_ids  = data.aws_subnet_ids.private.ids
  description = "Managed by Octopus with Terraform"

  tags = {
    Name = "${var.envName}-cloverdx-db-subnets"
  }
}

output "db_instance_dns_name" {
  value = aws_rds_cluster.sqlserver.endpoint
}
