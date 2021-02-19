provider "aws" {
<<<<<<< HEAD
  region  = var.region
#  profile = "fv-us"
=======
  #  region  = "us-west-2"
  #  profile = "fv-us"
>>>>>>> feature/deploy_rds: Ran terraform fmt
  assume_role {
    role_arn = var.assume_role_arn
  }
}

provider "aws" {
  alias   = "filevine"
}

provider "octopusdeploy" {
  address = var.octopus_provider_server_address
  apikey  = var.octopus_api_key
  space   = var.octopus_space
}

# this sets up future configuration to use the remote backend created in the backend directory
# Note that the workspaces prefix doesn't allow interporlation, so this is the same as what's set in variables
terraform {
  backend "s3" {
    bucket               = "fv-global-fv-tf-backend"
    key                  = "filevine-clover-servers"
    dynamodb_table       = "fv-global-fv-tf-backend-table"
    region               = "us-west-2"
    encrypt              = true
    workspace_key_prefix = "filevine-clover-workspaces"
  }
}
