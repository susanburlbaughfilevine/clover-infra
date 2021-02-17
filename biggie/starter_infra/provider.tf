provider "aws" {
  assume_role {
    role_arn = var.assume_role_arn
  }
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
