
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

variable "tools_instance_type" {
  description = "AWS Instance Type"
  default     = "m5a.8xlarge"
}

# Clover Specific settings
variable "clover_database_url" {
  description = "clover database url"
  type        = string
  default     = "import.filevinedev.com"
}

variable "clover_database_db" {
  description = "clover_database_db"
  type        = string
  default     = "clover_db"
}

variable "clover_database_user" {
  description = "clover_database_user"
  type        = string
  default     = "database_user"
}

variable "clover_database_pass" {
  description = "clover database pass"
  type        = string
  default     = "database_pass"
}
