
variable "envName" {
    description = ""
    type        = string
    default     = "dev"
}

# variable "aws_region" {
#     description = "What region are we executing in?"
#     type        = string
#     default     = "us-west-2"
# }
variable "aws_sg_import_frontend" {
    #default = "${var.envName}-DatastoresAccess"
}
variable "aws_sg_import_backend" {
    #default = "${var.envName}-DatastoresAccess"
}
variable "aws_sg_import_tech_access" {
    #default = "${var.envName}-DatastoresAccess"
}
variable "aws_sg_import_data_access" {
    #default = "${var.envName}-DatastoresAccess"
}
variable "aws_sg_import_octopus" {
    #default = "${var.envName}-DatastoresAccess"
}


# variable "aws_role" {
#   description = "Role ARN to assume the target of where to run this given terraform against"
#
# }

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
  default     = "demo"
}

variable "ami_status" {
  description = "AMI to grab, based on the tagging.  Values of testing & released."
  type        = string
  default     = "released"
}


variable "octopus_server_address" {
  description = "Octopus Server Address when running from inside AWS (Private IP typically) - Viewpoint of server being built"
  default     = "http://172.31.10.85:88"
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
  default     = "t3a.medium"
}

# =====================================
# define undeclared variables
# =====================================
#variable "" {

#}

# These variables can be reused through the configuration. Change the default value to the values you desire.
# variable "env_name" {
#     description = "The name to use to make resources unique"
#     type        = string
#     default     = "clover-staging-us"
#     # default     = "filevine-prod-us"`
# }

# variable "encryption_arn" {
#     description = "The ARN of the encyrption key to use in this environment"
#     type        = string
#     default     = "arn:aws:kms:us-west-2:530929067887:key/4309596a-4479-4f2b-ac62-b20b3b3a1a25"
# }

# variable "ami_status" {
#     description = ""
#     type        = string
#     default     = "released"
# }

# variable "security_group_ids" {
#     description = "A list of security group id's"
#     type        = list(string)
#     # FIXME: What are the security groups that are we currently using?
#     # Imports - Jonathan
#     # * sg-6cb81114
#     # Import Team Users II
#     # * sg-06bc8c0760f8403a6
#     # Dev-Wes - For my access
#     # * sg-12b6bc77
#     # Internal Access - For access to the databases
#     # * sg-4a92a82c
#     default     = ["sg-6cb81114", "sg-06bc8c0760f8403a6", "sg-12b6bc77", "sg-4a92a82c"]

 #    # default     = ["sg-33b4be56", "sg-16534673", "sg-12b6bc77", "sg-bc4a80d9"]
#     # default     = [aws_security_group.dev-wes, aws_security_group.database-group1, aws_security_group.production-security-group, aws_security_group.octopus]
# }

# variable "security_group_map" {
#     type      =     map
#     # Based on region
#     default={
#         "us-west-2"=["sg-6cb81114", "sg-06bc8c0760f8403a6", "sg-12b6bc77", "sg-4a92a82c"]
#         "ca-central-1"=["sg-66b4310d","sg-d2b732b9","sg-0341dea8e3ed6e450"]
#     }
# }

#encryption_arn                  =   "arn:aws:kms:ca-central-1:530929067887:key/cdbf6948-10e5-47d7-950e-03f48896d27a"

# variable "subnet_map" {
#     type      =     map
#     default={
#         "us-west-2"=["subnet-03253361", "subnet-23201157", "subnet-5ae4b41c", "subnet-e37ed3c8"]
#         "ca-central-1"=["subnet-91cc23f8","subnet-ea444a92"]
#     }
# }

#variable "encryption_map" {
#    type      =     map
#    default={
#        "us-west-2"="arn:aws:kms:us-west-2:530929067887:key/4309596a-4479-4f2b-ac62-b20b3b3a1a25"
#        "ca-central-1"="arn:aws:kms:ca-central-1:530929067887:key/cdbf6948-10e5-47d7-950e-03f48896d27a"
#    }
#}

#variable "subnet_ids" {
#    description = "A list of subnet id's"
#    type        = list(string)
#    default     = ["subnet-03253361", "subnet-23201157", "subnet-5ae4b41c", "subnet-e37ed3c8"]
#}

# variable "instance_type" {
#     description = "Instance type of server to build"
#     type        = string
#     default     = "r5a.4xlarge"
# }

variable "root_disk_space" {
    description = "Root Disk Space - you need to replace the entire system to adjust this space"
    type        = number
    default     = 30
}

# FIXME/HACK - bad security practice
# Either move assets to artifactory or fix s3 security group access
#variable "s3_access_key" {
#    description = "s3 access key"
#    type        = string
#    default     = "s3_access_key"
#}

#variable "s3_secret_key" {
#    description = "s3 secret key"
#    type        = string
#    default     = "s3_secret_key"
#}

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

#variable "fv_clover_rdp_admin_password" {
#    description = "Clover System rdp access users"
#    type        = string 
#    default     = ""
#}

#variable "susan_rdp_admin_password" {
#    description = "Clover System rdp access users"
#    type        = string 
#    default     = ""
#}

#variable "bporter_rdp_admin_password" {
#    description = "Clover System rdp access users"
#    type        = string 
#    default     = ""
#}

# variable "octopus_server_address" {
#     description = "Octopus Server Address when running from inside AWS (Private IP typically) - Viewpoint of server being built"
#     default = "http://172.31.10.85:88"
# }

# variable "octopus_provider_server_address" {
#     description = "Use to set the Provider Octopus Server Address - Viewpoint of system running terraform"
#     default = "https://octopus.filevinedev.com"
# }

# variable "octopus_api_key" {
#     description = "Octopus API key"
#     type        = string
#     default     = ""
# }


# variable "octopus_server_environment_metal" {
#     description = "Octopus Server Environment"
#     type        = string
#     default     = "test"
# }


# variable "octopus_server_environment" {
#     description = "Octopus Server Environment"
#    type        = string
#    default     = "test"
#}

#variable "octopus_server_roles" {
#    description = "octopus server roles"
#    type        = string
#    default     = "web"
#}

#variable "octopus_listen_port" {
#    description = "octopus server roles"
#    type        = string
#    default     = "10933"
#}

#variable "octopus_server_space" {
#    description = "octopus server roles"
#    type        = string
#    default     = "Metal"
#}

#variable "ps_name" {
#    description = "Partnership Server Group Name"
#    type        = string
#    default     = ""
#}

# --------------------------------------------------------------------------------------
# Updates for Filevine Tenent environment
# --------------------------------------------------------------------------------------
#variable "fv_devops_secret_key" {
#  description = "the aws secret key that will allow us to access filevine-devops bucket"
#}

#variable "fv_devops_access_key" {
#  description = "the aws access key that will allow us to access filevine-devops bucket"
#}

