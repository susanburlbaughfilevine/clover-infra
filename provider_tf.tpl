#this defines that were are using the aws provider and what region and profile to work against for all the files in this directory
provider "aws" {
  # region  = "us-west-2"
  region  = "|PROVIDER_AWS_REGION|"
  # profile = "fv-us"
  profile = "fv-us"
}

# this sets up future configuration to use the remote backend created in the backend directory
# Note that the workspaces prefix doesn't allow interporlation, so this is the same as what's set in variables
terraform {
  backend "s3" {
    bucket         = "fv-global-fv-tf-backend"
    key            = "cloverdx/|PROVIDER_S3_YEAR|/|PROVIDER_S3_MONTH|/|PROVIDER_S3_ENV|"
    dynamodb_table = "fv-global-fv-tf-backend-table"
    region         = "us-west-2"
    profile        = "fv-us"
    encrypt        = true
  }
}
