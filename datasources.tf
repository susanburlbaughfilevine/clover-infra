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

output "frontend-security-group" {
  value = "frontend-security group: ${data.aws_security_group.frontend.arn}"
}

data "aws_security_group" "backend" {
  name = "${var.envName}-Backend"
}

output "backend-security-group" {
  value = "backend-security group: ${data.aws_security_group.backend.arn}"
}

data "aws_security_group" "techaccess" {
  name = "${var.envName}-TechAccess"
}

output "techaccess-security-group" {
  value = "techaccess-security group: ${data.aws_security_group.techaccess.arn}"
}


data "aws_security_group" "dataaccess" {
  name = "${var.envName}-DatastoresAccess"
}

output "datastores-security-group" {
  value = "dataaccess-security group: ${data.aws_security_group.dataaccess.arn}"
}

data "aws_security_group" "build" {
  name = "${var.envName}-Build"
}

output "build-security-group" {
  value = "build-security group: ${data.aws_security_group.build.arn}"
}

data "aws_s3_bucket" "accesslogs" {
  bucket = "${data.aws_iam_account_alias.current.account_alias}-lblogs-${var.region}"
}

data "aws_ami" "windows" {
  most_recent = true

  filter {
    name = "name"
    values = ["win2019-base-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name = "tag:status"
    values = [var.ami_status]
  }

  owners = ["530929067887"] # Filevine
}