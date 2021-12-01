
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
    name = "tag-value"
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

data "aws_kms_alias" "default" {
  name = "alias/fv/default"
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
