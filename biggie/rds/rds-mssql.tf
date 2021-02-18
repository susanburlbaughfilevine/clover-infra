locals {
  env = lower(var.envName)
}

resource "aws_db_instance" "sqlserver" {
  identifier = "${local.env}-clover"
  allocated_storage     = var.rds-storage
  max_allocated_storage = var.rds-max-storage
  storage_type          = var.rds-storage-type
  engine                = var.sql_server_engine
  engine_version        = "13.00.5598.27.v1"
  instance_class        = var.rds-instance-class

  db_subnet_group_name   = aws_db_subnet_group.sqlserver.name
  vpc_security_group_ids = [data.aws_security_group.sqlserver.id]
  multi_az               = var.multi_az

  deletion_protection         = true
  final_snapshot_identifier   = "${local.env}-clover-FinalBackupBeforeDelete"
  auto_minor_version_upgrade  = false
  allow_major_version_upgrade = false
  apply_immediately           = var.apply_immediately

  enabled_cloudwatch_logs_exports = ["agent", "error"]
  maintenance_window              = "sun:09:00-sun:11:00"

  parameter_group_name = aws_db_parameter_group.sqlserver.name
  option_group_name    = aws_db_option_group.sqlserver.name

  license_model = "license-included"
  kms_key_id    = data.aws_kms_alias.sqlserver.target_key_arn

  storage_encrypted     = true
  copy_tags_to_snapshot = true

  username = "cloveradmin"
  password = var.db_password

  backup_window           = var.backup_window
  backup_retention_period = var.backup_retention_period

  timeouts {
    create = "90m"
    delete = "90m"
  }
}

resource "aws_db_parameter_group" "sqlserver" {
  name        = "${local.env}-filevine-se-13-00"
  family      = "sqlserver-se-13.0"
  description = "Managed by Octopus with Terraform"

  # The names of the paramaters can be copied directly from any RDS paramater Group in the AWS console.
  parameter {
    name  = "optimize for ad hoc workloads"
    value = "1"
  }

  parameter {
    name  = "min memory per query (kb)"
    value = "2048"
  }

}

resource "aws_iam_role" "sqlserverbackup" {
  name               = "${local.env}-sqlserver-NativeBackupRole"
  path               = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement":
    [{
        "Effect": "Allow",
        "Principal": {"Service":  "rds.amazonaws.com"},
        "Action": "sts:AssumeRole"
    }]
}
EOF

}

// TODO:  Do we have any custom settings?
resource "aws_db_option_group" "sqlserver" {
  name                     = "${local.env}-clover-se-13-00"
  option_group_description = "Option Group for Clover Application MSSQL"
  engine_name              = "sqlserver-se"
  major_engine_version     = "13.00"

  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"

    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.sqlserverbackup.arn
    }
  }

  tags = {
    Name       = "${local.env}-clover-13.00"
    managed_by = "octopus"
  }
}

resource "aws_db_subnet_group" "sqlserver" {
  name        = "${local.env}-clover-db-subnets"
  subnet_ids  = data.aws_subnet_ids.private.ids
  description = "Managed by Octopus with Terraform"

  tags = {
    Name = "${local.env}-clover-db-subnets"
  }
}