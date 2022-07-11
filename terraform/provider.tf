/* 
provider "newrelic" {
  account_id = var.nr_account_id
  api_key    = var.nr_api_key
  region     = "US"
} 
*/

provider "aws" {
  #  region  = "us-west-2"
  #  profile = "fv-us"
  assume_role {
    role_arn = var.assume_role_arn
  }
}

provider "aws" {
  alias = "filevine"
}

provider "aws" {
  alias = "platform"
  assume_role {
    role_arn = "arn:aws:iam::358974996326:role/Terraform"
  }
}

# this sets up future configuration to use the remote backend created in the backend directory
# Note that the workspaces prefix doesn't allow interpolation, so this is the same as what's set in variables
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
