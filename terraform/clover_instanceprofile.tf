

data "aws_iam_policy" "amazon_s3_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy" "cloudwatch_access" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "attach_amazon_ssm_managed_instance_core" {
  role       = aws_iam_role.clover.name
  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
}

resource "aws_iam_role" "clover" {
  name               = local.iam_instance_profile
  description        = "This role is for CloverDX Application to have access to appropriate resources"
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
    Name       = "${data.aws_iam_account_alias.current.account_alias}-role-Clover-InstanceProfile"
    managed_by = "terraform"
  }
}
resource "aws_iam_role_policy_attachment" "s3_full_access_policy" {
  role       = aws_iam_role.clover.name
  policy_arn = data.aws_iam_policy.amazon_s3_full_access.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy_attach" {
  role       = aws_iam_role.clover.name
  policy_arn = data.aws_iam_policy.cloudwatch_access.arn
}

resource "aws_iam_instance_profile" "clover" {
  name = aws_iam_role.clover.name
  role = aws_iam_role.clover.name
}

resource "aws_iam_role_policy" "textractassume" {
  name = "${var.envName}-Textract-PassRole"
  role = aws_iam_role.clover.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "MySid",
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "${aws_iam_role.textract.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "secrets_manager_access" {
  name = "${var.envName}-sm-access"
  path = "/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:UpdateSecret",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:*:*:secret:*"
      },
      {
        Sid      = "ListAllSecrets",
        Effect   = "Allow",
        Action   = "secretsmanager:ListSecrets",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "rds_full_read" {
  name = "${var.envName}-rds-read"
  path = "/"

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "RdsFullRead"
          Effect = "Allow"
          Action = [
            "rds:DescribeDBProxyTargetGroups",
            "rds:DescribeDBInstanceAutomatedBackups",
            "rds:DescribeDBEngineVersions",
            "rds:DescribeDBSubnetGroups",
            "rds:DescribeGlobalClusters",
            "rds:DescribeExportTasks",
            "rds:DescribePendingMaintenanceActions",
            "rds:DescribeEngineDefaultParameters",
            "rds:DescribeDBParameterGroups",
            "rds:DescribeDBClusterBacktracks",
            "rds:DescribeRecommendations",
            "rds:DescribeCustomAvailabilityZones",
            "rds:DescribeReservedDBInstancesOfferings",
            "rds:DescribeDBProxyTargets",
            "rds:DescribeRecommendationGroups",
            "rds:DownloadDBLogFilePortion",
            "rds:DescribeDBInstances",
            "rds:DescribeSourceRegions",
            "rds:DescribeEngineDefaultClusterParameters",
            "rds:DescribeInstallationMedia",
            "rds:DescribeDBProxies",
            "rds:DescribeDBParameters",
            "rds:DescribeEventCategories",
            "rds:DescribeDBProxyEndpoints",
            "rds:DescribeEvents",
            "rds:DescribeDBClusterSnapshotAttributes",
            "rds:DescribeDBClusterParameters",
            "rds:DescribeEventSubscriptions",
            "rds:DescribeDBSnapshots",
            "rds:DescribeDBLogFiles",
            "rds:DescribeDBSecurityGroups",
            "rds:DescribeDBSnapshotAttributes",
            "rds:DescribeReservedDBInstances",
            "rds:ListTagsForResource",
            "rds:DescribeValidDBInstanceModifications",
            "rds:DescribeDBClusterSnapshots",
            "rds:DescribeOrderableDBInstanceOptions",
            "rds:DescribeOptionGroupOptions",
            "rds:DownloadCompleteDBLogFile",
            "rds:DescribeDBClusterEndpoints",
            "rds:DescribeCertificates",
            "rds:DescribeDBClusters",
            "rds:DescribeAccountAttributes",
            "rds:DescribeOptionGroups",
            "rds:DescribeDBClusterParameterGroups"
          ]
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_policy" "iam_management_policy" {
  name = "${var.envName}-iam-management"
  path = "/"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "iam:CreatePolicy",
          "iam:AddUserToGroup",
          "iam:GetUserPolicy",
          "iam:AttachUserPolicy",
          "iam:AttachRolePolicy",
          "iam:GetUser",
          "iam:CreateUser",
          "iam:CreateAccessKey",
          "iam:ListUsers",
          "iam:CreateLoginProfile"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "iam_management_attach" {
  role       = aws_iam_role.clover.name
  policy_arn = aws_iam_policy.iam_management_policy.arn
}


resource "aws_iam_role_policy_attachment" "sm_access_attach" {
  role       = aws_iam_role.clover.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

resource "aws_iam_role_policy_attachment" "rds_read_attach" {
  role       = aws_iam_role.clover.name
  policy_arn = aws_iam_policy.rds_full_read.arn
}

resource "aws_iam_role" "textract" {
  name               = "AmazonTextractRole-${var.envName}"
  description        = "Allows Textract to call AWS services on your behalf for ${var.envName}"
  assume_role_policy = data.aws_iam_policy_document.textract-trust.json
}


data "aws_iam_policy" "textractservicerole" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonTextractServiceRole"
}

resource "aws_iam_role_policy_attachment" "textractservicerole" {
  role       = aws_iam_role.textract.name
  policy_arn = data.aws_iam_policy.textractservicerole.arn
}

data "aws_iam_policy_document" "textract-trust" {

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["textract.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "ec2describe" {
  name = "EC2-Describe"
  role = aws_iam_role.clover.id

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
  role   = aws_iam_role.clover.id
}

