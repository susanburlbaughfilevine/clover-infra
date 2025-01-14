locals {
  cs_cidr     = split(",", var.filevine_common_services_cidr)
  cs_cidr1    = concat(local.cs_cidr, formatlist(var.filevine_shard_cidr))
  cidr_blocks = concat(local.cs_cidr1, formatlist(data.aws_vpc.clover.cidr_block))
}
locals {
  canada_sg = var.internal_sg_canada == "$null" ? ["nothing"] : [var.internal_sg_canada]
}

output "filevine_common_services_cidr" {
  value = var.filevine_common_services_cidr
}
output "cs_cidr" {
  value = local.cs_cidr
}
output "cs_cidr1" {
  value = local.cs_cidr1
}
output "cidr_blocks" {
  value = local.cidr_blocks
}
variable "internal_sg_canada" {
  description = "SG needed for dm-canada and cloverdx to migrate to CA shards."
  type        = string
}

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
  default = "true"
}

variable "zpa_subnet_cidr" {
  description = "Subnet (in CIDR notation) from which incoming ZPA requests will originate"
  default     = "172.17.64.0/21"
}

variable "filevine_shard_cidr" {
  description = "Subnets where Filevine Shards exist for the cell"
}

variable "filevine_common_services_cidr" {
  description = "This a CIDR for common services of this cell"
}

variable "nr_slack_webhook" {

}

variable "nr_slack_channel" {

}

variable "nr_account_id" {

}

variable "nr_api_key" {

}

##########################
# Instance / Lun Storage Variables 
##########################
variable "ec2_storage_size" {
  description = "Storage Size"
  default     = 200
}

variable "ec2_storage_type" {
  description = "Storage Type.  Options include gp2 and gp3.  Default is gp3"
  default     = "gp3"
}

variable "ebs_lun_storage_size" {
  description = "Storage Size"
  default     = 3200
}

variable "ebs_lun_storage_type" {
  description = "Storage Type.  Options include gp2 and gp3.  Default is gp3"
  default     = "gp3"
}

# Short Host Name
variable "short_host_name_worker" {
  description = "short host name in case instance name fails to set full name"
  default     = "clover-worker"
}
variable "short_host_name_clover" {
  description = "short host name in case instance name fails to set full name"
  default     = "clover"
}
