
variable "envName" {
  description = ""
  type        = string
  default     = "dev"
}

variable "aws_role" {
  description = "Role ARN to assume the target of where to run this given terraform against"
}

variable "assume_role_arn" {
  description = "Role ARN to assume for the target of where to run this given terraform against"
}

variable "region" {
  description = "Region to deploy into"
  default     = "us-west-2"
}
variable "dns_domain" {
  description = "DNS Domain this system lives in"
  default     = "filevinedev.com"
}

variable "subdomain" {
  description = "Subdomain to uniquely identify this frontend"
}

variable "clover_domain" {
  description = "CloverDX endpoint"
}

variable "shorturl_dns_domain" {
  description = "DNS Domain used for URL sharing creation.  Shorter than normal domain."
  default     = "filev.io"
}

variable "ami_status" {
  description = "AMI to grab, based on the tagging.  Values of testing & released."
  type        = string
  default     = "released"
}

variable "octopus_server_address" {
  description = "Octopus Server Address when running from inside AWS (Private IP typically) - Viewpoint of server being built"
  default     = "http://internal-octopus.filevinedev.com:88"
}

variable "octopus_provider_server_address" {
  description = "Use to set the Provider Octopus Server Address - Viewpoint of system running terraform - typically inside AWS will be internal IP of octopus"
  default     = "https://octopus.filevinedev.com"

}

variable "octopus_api_key" {
  description = "Octopus API Key for linking tentacle to main server"
}

variable "octopus_space" {
  description = "Octopus Space to connect this instance to"
  default     = "Default"
}

variable "octopus_server_environment" {
  description = "Environment to connect this instance to in Octopus"
  default     = "dummy-dev"
}

variable "octopus_tenant" {
  description = "Octopus Tenant to associate with"
  default     = "dev"
}

variable "octopus_target_project" {
  description = "Target Octopus project to push variables into"
  default     = "Dev"
}

variable "instance_type" {
  description = "AWS Instance Type"
  default     = "c5.xlarge"
}

variable "rds_storage" {
  description = "Storage for the MS SQL Server"
  default     = "200"
}

variable "rds_max_storage" {
  description = "Maximum Allocated Storage for SQL server to grow into"
  default     = "1024"
}

variable "rds_storage_type" {
  description = "Storage Type for RDS"
  default     = "gp2"
}

#
# Database Engine and version supported by CloverDX - https://doc.cloverdx.com/latest/server/system-requirements-for-cloverdx-server.html#d5e797"
#
variable "rds_engine" {
  description = "Database Engine supported by CloverDX"
  default     = "sqlserver-se"
}

variable "rds_engine_version" {
  description = "Database Engine version supported by CloverDX"
  default     = "13.00.5882.1.v1"
}

variable "rds_instance_class" {
  description = "Instance class for size of instances to use"
  default     = "db.r5.large"
}

variable "rds_multi_az" {
  description = "Is this deployment setup for Multi-AZ?"
  default     = "false"
}

variable "rds_user_name" {
  description = "RDS instance user name"
}

variable "rds_user_password" {
  description = "RDS instance password"
}

variable "newrelic_enabled" {
  default = "false"
}

variable "zpa_subnet_cidr" {
  description = "Subnet (in CIDR notation) from which incoming ZPA requests will originate"
  default     = "172.17.64.0/21"
}

variable "filevine_shard_cidr" {
}

variable "workernode_address" {
  default = {
    address = aws_route53_record.clover_worker_db_record.fqdn
  }

  type = map(string)
}