locals {
  db_options = {
    sqlserver-se = {
      license_model = "license-included"
      export_logs   = ["agent", "error"]
      port          = 1433
    }
    postgres = {
      license_model = "postgresql-license"
      export_logs   = ["postgresql", "upgrade"]
      port          = 5432
    }
    mysql = {
      license_model = "general-public-license"
      export_logs   = ["audit", "error", "general", "slowquery"]
      port          = 1433
    }
  }
}

resource "aws_db_instance" "sqlserver" {
  identifier = lower("${var.envName}-cloverdx")

  allocated_storage     = var.rds_storage
  max_allocated_storage = var.rds_max_storage
  storage_type          = var.rds_storage_type
  engine                = var.rds_engine
  engine_version        = var.rds_engine_version
  instance_class        = var.rds_instance_class

  db_subnet_group_name   = aws_db_subnet_group.sqlserver.name
  vpc_security_group_ids = [aws_security_group.dataaccess.id]
  multi_az               = var.rds_multi_az

  deletion_protection         = false
  auto_minor_version_upgrade  = false
  allow_major_version_upgrade = false
  skip_final_snapshot         = true

  enabled_cloudwatch_logs_exports = local.db_options[var.rds_engine].export_logs
  maintenance_window              = "sun:09:00-sun:11:00"

  license_model = local.db_options[var.rds_engine].license_model
  kms_key_id    = data.aws_kms_alias.default.target_key_arn

  storage_encrypted     = true
  copy_tags_to_snapshot = true

  username = var.rds_user_name
  password = var.rds_user_password

  backup_window           = "07:00-08:00"
  backup_retention_period = 35

  timeouts {
    create = "90m"
    delete = "90m"
  }
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
  value = aws_db_instance.sqlserver.address
}
