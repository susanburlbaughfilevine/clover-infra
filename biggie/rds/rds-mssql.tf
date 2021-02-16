resource "aws_db_instance" "sqlserver" {
  identifier = "${var.envName}-clover"
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
  final_snapshot_identifier   = "${var.envName}-clover-FinalBackupBeforeDelete"
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
  name        = "${var.envName}-filevine-se-13-00"
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

// TODO:  Do we have any custom settings?
resource "aws_db_option_group" "sqlserver" {
  name                     = "${var.envName}-clover-se-13-00"
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
    Name       = "${var.envName}-clover-13.00"
    managed_by = "octopus"
  }
}

resource "aws_db_subnet_group" "sqlserver" {
  name        = "${var.envName}-clover-db-subnets"
  subnet_ids  = data.aws_subnet_ids.private.ids
  description = "Managed by Octopus with Terraform"

  tags = {
    Name = "${var.envName}-clover-db-subnets"
  }
}



# Create CloudWatch Metric Alarm
# https://www.terraform.io/docs/providers/aws/r/cloudwatch_metric_alarm.html

# RDS High CPU Alarm 90% Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu_cwa_90" {
  depends_on          = [data.aws_sns_topic.slack_sns_topic]
  alarm_name          = "${var.envName}-clover-rds-high-cpu-90"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors RDS cpu utilization at >=90%"
  actions_enabled     = true
  alarm_actions       = [data.aws_sns_topic.slack_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.sqlserver.id
  }
  insufficient_data_actions = []
}

# RDS High CPU Alarm 95% Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_cpu_cwa_95" {
  depends_on          = [data.aws_sns_topic.slack_sns_topic]
  alarm_name          = "${var.envName}-clover-rds-high-cpu-95"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Maximum"
  threshold           = "95"
  alarm_description   = "This metric monitors RDS cpu utilization >=95%"
  actions_enabled     = true
  alarm_actions       = [data.aws_sns_topic.slack_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.sqlserver.id
  }
  insufficient_data_actions = []
}

# RDS High Read IOPS Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_read_iops" {
  depends_on          = [data.aws_sns_topic.slack_sns_topic]
  alarm_name          = "${var.envName}-clover-rds-high-read-iops"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "10"
  metric_name         = "ReadIOPS"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "95"
  alarm_description   = "This metric monitors RDS cpu utilization"
  actions_enabled     = true
  alarm_actions       = [data.aws_sns_topic.slack_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.sqlserver.id
  }
  insufficient_data_actions = []
}

# RDS Low Free Storage Space Alarm
resource "aws_cloudwatch_metric_alarm" "rds_low_free_storage_space" {
  depends_on          = [data.aws_sns_topic.slack_sns_topic]
  alarm_name          = "${var.envName}-clover-rds-low-free-storage-space"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "1099511627776"
  alarm_description   = "This metric monitors low free storage space"
  actions_enabled     = true
  alarm_actions       = [data.aws_sns_topic.slack_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.sqlserver.id
  }
  insufficient_data_actions = []
}

# RDS High DB Connections >=500 Alarm
resource "aws_cloudwatch_metric_alarm" "rds_high_db_connections-500" {
  depends_on          = [data.aws_sns_topic.slack_sns_topic]
  alarm_name          = "${var.envName}-clover-rds-high-db-connections-500"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "5"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "60"
  statistic           = "Average"
  threshold           = "500"
  alarm_description   = "This metric monitors high db connections >=500"
  actions_enabled     = true
  alarm_actions       = [data.aws_sns_topic.slack_sns_topic.arn]
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.sqlserver.id
  }
  insufficient_data_actions = []
}

# Create RDS Event Subscription
# https://www.terraform.io/docs/providers/aws/r/db_event_subscription.html
resource "aws_db_event_subscription" "db_event_subcription" {
  name        = "${var.envName}-clover-rds-event-subscription"
  sns_topic   = data.aws_sns_topic.slack_sns_topic.arn
  source_type = "db-instance"
  source_ids  = [aws_db_instance.sqlserver.id]

  event_categories = [
    "availability",
    "deletion",
    "failover",
    "failure",
    "low storage",
    "maintenance",
    "notification",
    "read replica",
    "recovery",
    "restoration",
  ]
}

# Create QA RDS Snapshot Event Subscription
# https://www.terraform.io/docs/providers/aws/r/db_event_subscription.html
resource "aws_db_event_subscription" "db_snapshot_subcription" {
  name        = "${var.envName}-clover-rds-event-subscription-snapshots"
  sns_topic   = data.aws_sns_topic.slack_sns_topic.arn
  source_type = "db-snapshot"
}
