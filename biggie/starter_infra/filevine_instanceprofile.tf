data "aws_iam_policy" "cloudwatch_agent_server_policy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy" "amazon_ssm_managed_instance_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "cloverapp_instance_profile" {
  name               = "${var.envName}-CloverApp-InstanceProfile"
  description        = "This role is for Clover Application to have access to appropriate resources"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name       = "${data.aws_iam_account_alias.current.account_alias}-role-CloverApp-InstanceProfile"
    managed_by = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "attach_amazon_ssm_managed_instance_core" {
  role       = aws_iam_role.cloverapp_instance_profile.name
  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  role       = aws_iam_role.cloverapp_instance_profile.name
  policy_arn = data.aws_iam_policy.cloudwatch_agent_server_policy.arn
}

resource "aws_iam_instance_profile" "cloverapp_instance_profile" {
  name = aws_iam_role.cloverapp_instance_profile.name
  role = aws_iam_role.cloverapp_instance_profile.name
}

resource "aws_iam_role_policy" "ec2describe" {
  name = "EC2-Describe"
  role = aws_iam_role.cloverapp_instance_profile.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
                  "ec2:DescribeInstances",
                  "elasticloadbalancing:DescribeLoadBalancers"
                ],
      "Resource": "*"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "ec2taggingPol" {
  statement {
    sid    = "AllowEc2Tagging"
    effect = "Allow"
    actions = [
      "ec2:DeleteTags",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ec2tagging" {
  name   = "Ec2Tagging"
  policy = data.aws_iam_policy_document.ec2taggingPol.json
  role   = aws_iam_role.cloverapp_instance_profile.id
}