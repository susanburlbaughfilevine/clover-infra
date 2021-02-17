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

output "vpc-id" {
  value = "vpc-id: ${data.aws_vpc.clover.id}"
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

output "frontend-security-group" {
  value = "frontend-security group: ${var.aws_sg_import_frontend}"
}

data "aws_security_group" "frontend" {
  name = "${var.envName}-clover-FrontEnd"
}

output "frontend-security-group-arn" {
  value = "frontend-security group: ${data.aws_security_group.frontend.arn}"
}

output "backend-security-group" {
  value = "backend-security group: ${var.aws_sg_import_backend}"
}
data "aws_security_group" "backend" {
<<<<<<< HEAD
  name = var.aws_sg_import_backend
=======
  name = "${var.envName}-clover-Backend"
>>>>>>> not quite working right
}

output "backend-security-group-arn" {
  value = "backend-security group: ${data.aws_security_group.backend.arn}"
}

data "aws_security_group" "techaccess" {
<<<<<<< HEAD
  name = var.aws_sg_import_tech_access
=======
  name = "${var.envName}-clover-TechAccess"
>>>>>>> not quite working right
}

output "techaccess-security-group-arn" {
  value = "techaccess-security group: ${data.aws_security_group.techaccess.arn}"
}

data "aws_security_group" "dataaccess" {
<<<<<<< HEAD
  name = var.aws_sg_import_data_access
=======
  name = "${var.envName}-clover-DatastoresAccess"
>>>>>>> not quite working right
}

output "datastores-security-group-arn" {
  value = "dataaccess-security group: ${data.aws_security_group.dataaccess.arn}"
}

data "aws_security_group" "build" {
  name = var.aws_sg_import_octopus
}

output "build-security-group-arn" {
  value = "build-security group: ${data.aws_security_group.build.arn}"
}

data "aws_iam_instance_profile" "filevineApp" {
  name = var.instance_profile
}


data "aws_s3_bucket" "accesslogs" {
  bucket = "${data.aws_iam_account_alias.current.account_alias}-lblogs-${var.region}"
}

data "aws_ami" "windows" {
  most_recent = true

  filter {
    name   = "name"
    values = ["win2019-base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "tag:status"
    values = [var.ami_status]
  }

  owners = ["530929067887"] # Filevine
}
