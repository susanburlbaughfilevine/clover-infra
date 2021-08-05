provider "aws" {
  assume_role {
    role_arn = var.assume_role_arn
  }
}

provider "octopusdeploy" {
  address = var.octopus_provider_server_address
  apikey  = var.octopus_api_key
  space   = var.octopus_space
}

terraform {
  backend "s3" {
    bucket               = "fv-global-fv-tf-backend"
    key                  = "clover-sqlserver"
    dynamodb_table       = "fv-global-fv-tf-backend-table"
    region               = "us-west-2"
    encrypt              = true
    workspace_key_prefix = "fv-sqlserver-workspaces"
  }
}
