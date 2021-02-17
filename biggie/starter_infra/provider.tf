provider "aws" {
  assume_role {
    role_arn = var.assume_role_arn
  }
  alias = "clover"
}

provider "octopusdeploy" {
  address = var.octopus_provider_server_address
  apikey  = var.octopus_api_key
  space   = var.octopus_space
}

terraform {
  backend "s3" {
    bucket               = "fv-global-fv-tf-backend"
    key                  = "clover-starter-infra"
    dynamodb_table       = "fv-global-fv-tf-backend-table"
    region               = "us-west-2"
    encrypt              = true
    workspace_key_prefix = "clover-starter-infra-workspace"
  }
}
