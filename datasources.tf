# Security Groups

data "aws_region" "current" {
  name = var.region
}

data "aws_caller_identity" "current" {}

data "aws_iam_account_alias" "current" {}

data "aws_vpc" "clover" {
  filter {
    name   = "tag-key"
    values = ["Name"]
  }
  filter {
    name   = "tag-value"
    # values = [data.aws_iam_account_alias.current.account_alias]
    values = ["${data.aws_iam_account_alias.current.account_alias}-vpc"]

  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.clover.id

  tags = {
    Tier = "private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.clover.id

  tags = {
    Tier = "public"
  }
}

data "aws_kms_alias" "backend" {
  name = "alias/fv/server"
}

data "aws_security_group" "frontend" {
  name = var.aws_sg_import_frontend
}

output "frontend-security-group" {
  value = "frontend-security group: ${data.aws_security_group.frontend.arn}"
}

data "aws_security_group" "backend" {
  name = var.aws_sg_import_backend
}

output "backend-security-group" {
  value = "backend-security group: ${data.aws_security_group.backend.arn}"
}

data "aws_security_group" "techaccess" {
  name = var.aws_sg_import_tech_access
}

output "techaccess-security-group" {
  value = "techaccess-security group: ${data.aws_security_group.techaccess.arn}"
}

data "aws_security_group" "dataaccess" {
  name = var.aws_sg_import_data_access
}

output "datastores-security-group" {
  value = "dataaccess-security group: ${data.aws_security_group.dataaccess.arn}"
}

data "aws_security_group" "build" {
  name = var.aws_sg_import_octopus
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
