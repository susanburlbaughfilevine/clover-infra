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

  availability_zones = {
    ca-central-1 = [
      "ca-central-1a",
      "ca-central-1b",
      "ca-central-1c"
    ]

    us-west-2 = [
      "us-west-2a",
      "us-west-2b",
      "us-west-2c"
    ]
  }
}

resource "aws_rds_cluster" "sqlserver" {
  cluster_identifier           = lower("${var.envName}-cloverdx")
  availability_zones           = local.availability_zones[var.region]
  engine                       = "aurora-postgresql"
  engine_mode                  = "serverless"
  master_username              = var.rds_user_name
  master_password              = var.rds_user_password
  backup_retention_period      = 35
  preferred_backup_window      = "07:00-08:00"
  vpc_security_group_ids       = [aws_security_group.dataaccess.id]
  storage_encrypted            = true
  kms_key_id                   = data.aws_kms_alias.default.target_key_arn
  deletion_protection          = false
  db_subnet_group_name         = aws_db_subnet_group.sqlserver.name
  copy_tags_to_snapshot        = true
  preferred_maintenance_window = "sun:09:00-sun:11:00"
  skip_final_snapshot          = true
  final_snapshot_identifier    = "${var.envName}-cloverdx-final-snapshot"
  database_name                = "clover_db"

  scaling_configuration {
    max_capacity             = 16
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "RollbackCapacityChange"
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
  value = aws_rds_cluster.sqlserver.endpoint
}
