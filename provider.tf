provider "aws" {
#  region  = "us-west-2"
#  profile = "fv-us"
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
    bucket         = "fv-global-fv-tf-backend"
    key            = "filevine-clover-servers"
    dynamodb_table = "fv-global-fv-tf-backend-table"
    encrypt        = true
    workspace_key_prefix = "filevine-clover-workspaces"
  }
}

