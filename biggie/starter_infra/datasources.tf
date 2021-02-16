data "aws_caller_identity" "current" {}

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

data "aws_route53_zone" "master" {
  provider = aws.filevine
  name     = var.dns_domain
}

data "aws_kms_alias" "billing" {
  name = "alias/fv/default"
}
