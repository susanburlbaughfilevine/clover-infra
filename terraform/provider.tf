provider "aws" {
  #  region  = "us-west-2"
  #  profile = "fv-us"
  profile = "lockpick"
  region  = "us-west-2"
}

provider "aws" {
  alias   = "filevine"
  profile = "filevine"
  region  = "us-west-2"
}

provider "aws" {
  profile = "platform"
  alias   = "platform"
  region  = "us-west-2"
  # assume_role {
  #   role_arn = "arn:aws:iam::358974996326:role/Terraform"
  # }
}

# this sets up future configuration to use the remote backend created in the backend directory
# Note that the workspaces prefix doesn't allow interpolation, so this is the same as what's set in variables
terraform {
  backend "s3" {
    profile              = "filevine"
    bucket               = "fv-global-fv-tf-backend"
    key                  = "filevine-clover-servers"
    dynamodb_table       = "fv-global-fv-tf-backend-table"
    region               = "us-west-2"
    encrypt              = true
    workspace_key_prefix = "filevine-clover-workspaces"
  }
}
