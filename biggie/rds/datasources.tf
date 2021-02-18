data "aws_iam_account_alias" "current" {}

data "aws_region" "current" {}

data "aws_security_group" "sqlserver" {
  name = "${var.envName}-clover-DatastoresAccess"
}

data "aws_vpc" "clover" {
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


data "aws_kms_alias" "sqlserver" {
  name = "alias/fv/default"
}