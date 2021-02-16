data "aws_iam_account_alias" "current" {}

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


data "aws_kms_alias" "sqlserver" {
  name = "alias/fv/default"
}

data "aws_security_group" "sqlserver" {
  name = "${var.envName}-DatastoresAccess"
}

data "aws_sns_topic" "slack_sns_topic" {
  name = "${var.envName}-slack-alerting"
}
data "aws_iam_account_alias" "current" {}

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


data "aws_kms_alias" "sqlserver" {
  name = "alias/fv/default"
}

data "aws_security_group" "sqlserver" {
  name = "${var.envName}-DatastoresAccess"
}

data "aws_sns_topic" "slack_sns_topic" {
  name = "${var.envName}-slack-alerting"
}
