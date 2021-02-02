# Security Groups
data "aws_iam_account_alias" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "filevine" {
  filter {
    name   = "tag-key"
    values = ["Name"]
  }
  filter {
    name   = "tag-value"
    values = [data.aws_iam_account_alias.current.account_alias]
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.filevine.id

  tags = {
    Tier = "private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.filevine.id

  tags = {
    Tier = "public"
  }
}

data "aws_kms_alias" "backend" {
  name = "alias/fv/server"
}

data "aws_security_group" "frontend" {
  name = "${var.envName}-FrontEnd"
}

data "aws_security_group" "backend" {
  name = "${var.envName}-BackEnd"
}

data "aws_security_group" "techaccess" {
  name = "${var.envName}-TechAccess"
}

data "aws_security_group" "dataaccess" {
  name = "${var.envName}-DatastoresAccess"
}

data "aws_security_group" "build" {
  name = "${var.envName}-Build"
}

data "aws_s3_bucket" "accesslogs" {
  bucket = "${data.aws_iam_account_alias.current.account_alias}-lblogs-${var.region}"
}
