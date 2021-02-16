provider "aws" {
  assume_role {
    role_arn = var.assume_role_arn
  }
}
  
provider "aws" {
  alias = "filevine"
}

terraform {
  backend "s3" {
    bucket               = "fv-global-fv-tf-backend"
    key                  = "filevine-sqlserver"
    dynamodb_table       = "fv-global-fv-tf-backend-table"
    region               = "us-west-2"
    encrypt              = true
    workspace_key_prefix = "fv-sqlserver-workspaces"
  }
}
