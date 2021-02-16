variable "envName" {
  description = "Environment Name"
  default     = "dev"
}

variable "region" {
  description = "Region to deploy into"
  default     = "us-west-2"
}

variable "assume_role_arn" {
  description = "Role ARN to assume for the target of where to run this given terraform against"
}

// Setting default to 100 G so GP2 doesn't get significant slowdowns due to credit exhaustion as easily 
// Setting requires a minimum of 200G to start with
variable "rds-storage" {
  description = "Storage for the MS SQL Server"
  default     = "200"
}

variable "rds-max-storage" {
  description = "Maximum Allocated Storage for SQL server to grow into"
  default     = "1024"
}

variable "rds-storage-type" {
  description = "Storage Type for RDS"
  default     = "gp2"
}

variable "rds-instance-class" {
  description = "Instance class for size of instances to use"
  default     = "db.r5.large"
}

variable "db_password" {
  description = "Password for the FVDBAdmin account"
  default     = "AMXOepDUIQU0$a4!&46F!O6W%uk558cysVNYzgyWRXxqkJInbSbI"
}

variable "multi_az" {
  description = "RDS instance has a multi az configuration"
  default     = true
}

variable "backup_window" {
  description = "Time within which it is appropriate for RDS to run automatic backups"
  default     = "07:00-08:00"
}

variable "backup_retention_period" {
  description = "Number (in days) that RDS backups will be kept"
  default     = 35
}

variable "sql_server_engine" {
  description = "SQL Server engine to use"
  default     = "sqlserver-se"
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window. Can result in brief downtime if set to true"
  default     = "false"
}
