locals {
  worker = {
    address = aws_route53_record.clover_worker_db_record.fqdn
  }
}

resource "aws_secretsmanager_secret" "ssh_credentials" {
  name = "cloveretl-ssh-credentials"
}


resource "aws_secretsmanager_secret_version" "workernode_data" {
  secret_id     = aws_secretsmanager_secret.workernode.id
  secret_string = jsonencode(local.worker)
}

resource "aws_secretsmanager_secret" "workernode" {
  name = "workernode"
}

resource "aws_route53_record" "clover_worker_record" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "clover-worker-${var.envName}.${var.dns_domain}"
  type     = "CNAME"
  ttl      = 300
  records  = [aws_instance.clover_worker.private_dns]
}

resource "aws_instance" "clover_worker" {
  ami           = data.aws_ami.windows.id
  instance_type = var.instance_type

  tags = {
    Name       = "${var.envName}-clover-worker-0"
    managed_by = "terraform"
    env        = var.envName
  }

  vpc_security_group_ids = [
    aws_security_group.cloverdx.id,
    aws_security_group.dataaccess.id,
    aws_security_group.worker_dbaccess.id
  ]

  iam_instance_profile = local.iam_instance_profile
  subnet_id            = element(tolist(data.aws_subnet_ids.private.ids), 0)
  key_name             = local.key_name
  user_data = templatefile("${path.module}/userdata_worker.ps1", {
    octopus_api_key            = var.octopus_api_key
    octopus_server_address     = var.octopus_server_address
    octopus_server_environment = var.octopus_server_environment
    octopus_space              = var.octopus_space
    octopus_tenant             = var.octopus_tenant
    server_roles               = "clover-worker"
    scaleft_config             = file("${path.root}/sftd.yaml")
    newrelic_enabled           = var.newrelic_enabled
  })
  monitoring = false

  root_block_device {
    volume_size = var.ec2_storage_size
    volume_type = var.ec2_storage_type
    throughput  = module.gp3_matrix_ec2.storage_throughput
    iops        = module.gp3_matrix_ec2.storage_iops
    encrypted   = true
    kms_key_id  = data.aws_kms_alias.backend.target_key_arn
  }
  lifecycle {
    # uncomment when ready for production
    #  prevent_destroy = true
  }
}

resource "aws_ebs_volume" "clover_instance_volume_1" {
  availability_zone = aws_instance.clover_worker.availability_zone
  size              = var.ebs_lun_storage_size
  type              = var.ebs_lun_storage_type
  iops              = module.gp3_matrix_ebs_lun.storage_iops
  throughput        = module.gp3_matrix_ebs_lun.storage_throughput
  kms_key_id        = data.aws_kms_alias.backend.target_key_arn
  encrypted         = true

  tags = {
    Name = "${var.envName}-clover-worker--volume-1"
  }
}

resource "aws_volume_attachment" "clover_volume_attach_1" {
  device_name = "xvdg"
  instance_id = aws_instance.clover_worker.id
  volume_id   = aws_ebs_volume.clover_instance_volume_1.id
}
resource "aws_iam_role" "clover_worker" {
  name               = "${var.envName}-clover-worker-iam-role"
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

resource "aws_iam_instance_profile" "clover_worker" {
  name = "${local.iam_instance_profile}-worker"
  role = aws_iam_role.clover_worker.name
}

data "aws_iam_policy" "amazon_ssm_managed_instance_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_amazon_ssm_managed_instance_core_worker" {
  role       = aws_iam_role.clover_worker.name
  policy_arn = data.aws_iam_policy.amazon_ssm_managed_instance_core.arn
}

resource "aws_iam_role_policy" "clover_worker_policy_rds" {
  name = "${var.envName}-clover-worker-policy-rds"
  role = aws_iam_role.clover_worker.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "RdsReadAccess",
        "Effect" : "Allow",
        "Action" : [
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
          "rds:DescribeCustomAvailabilityZones",
          "rds:DescribeReservedDBInstancesOfferings",
          "rds:DescribeDBProxyTargets",
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
          "rds:DescribeDBClusterEndpoints",
          "rds:DescribeCertificates",
          "rds:DescribeDBClusters",
          "rds:DescribeAccountAttributes",
          "rds:DescribeOptionGroups",
          "rds:DescribeDBClusterParameterGroups"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sm_access_attach_worker" {
  role       = aws_iam_role.clover_worker.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

resource "aws_iam_role_policy" "clover_worker_policy_s3" {
  name = "${var.envName}-clover-worker-policy-s3"
  role = aws_iam_role.clover_worker.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3DmAccess",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutAnalyticsConfiguration",
          "s3:PutAccessPointConfigurationForObjectLambda",
          "s3:GetObjectVersionTagging",
          "s3:DeleteAccessPoint",
          "s3:CreateBucket",
          "s3:DeleteAccessPointForObjectLambda",
          "s3:GetStorageLensConfigurationTagging",
          "s3:ReplicateObject",
          "s3:GetObjectAcl",
          "s3:GetBucketObjectLockConfiguration",
          "s3:DeleteBucketWebsite",
          "s3:GetIntelligentTieringConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:GetObjectVersionAcl",
          "s3:DeleteObject",
          "s3:CreateMultiRegionAccessPoint",
          "s3:GetBucketPolicyStatus",
          "s3:GetObjectRetention",
          "s3:GetBucketWebsite",
          "s3:GetJobTagging",
          "s3:GetMultiRegionAccessPoint",
          "s3:PutReplicationConfiguration",
          "s3:PutObjectLegalHold",
          "s3:InitiateReplication",
          "s3:GetObjectLegalHold",
          "s3:GetBucketNotification",
          "s3:PutBucketCORS",
          "s3:DescribeMultiRegionAccessPointOperation",
          "s3:GetReplicationConfiguration",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObject",
          "s3:PutBucketNotification",
          "s3:DescribeJob",
          "s3:PutBucketLogging",
          "s3:GetAnalyticsConfiguration",
          "s3:PutBucketObjectLockConfiguration",
          "s3:GetObjectVersionForReplication",
          "s3:GetAccessPointForObjectLambda",
          "s3:GetStorageLensDashboard",
          "s3:CreateAccessPoint",
          "s3:GetLifecycleConfiguration",
          "s3:GetInventoryConfiguration",
          "s3:GetBucketTagging",
          "s3:PutAccelerateConfiguration",
          "s3:GetAccessPointPolicyForObjectLambda",
          "s3:DeleteObjectVersion",
          "s3:GetBucketLogging",
          "s3:ListBucketVersions",
          "s3:RestoreObject",
          "s3:ListBucket",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketPolicy",
          "s3:PutEncryptionConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetObjectVersionTorrent",
          "s3:AbortMultipartUpload",
          "s3:GetBucketRequestPayment",
          "s3:GetAccessPointPolicyStatus",
          "s3:UpdateJobPriority",
          "s3:GetObjectTagging",
          "s3:GetMetricsConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:DeleteBucket",
          "s3:PutBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetMultiRegionAccessPointPolicyStatus",
          "s3:ListBucketMultipartUploads",
          "s3:PutIntelligentTieringConfiguration",
          "s3:GetMultiRegionAccessPointPolicy",
          "s3:GetAccessPointPolicyStatusForObjectLambda",
          "s3:PutMetricsConfiguration",
          "s3:PutBucketOwnershipControls",
          "s3:DeleteMultiRegionAccessPoint",
          "s3:UpdateJobStatus",
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetAccessPointConfigurationForObjectLambda",
          "s3:PutInventoryConfiguration",
          "s3:GetObjectTorrent",
          "s3:GetStorageLensConfiguration",
          "s3:DeleteStorageLensConfiguration",
          "s3:PutBucketWebsite",
          "s3:PutBucketRequestPayment",
          "s3:PutObjectRetention",
          "s3:CreateAccessPointForObjectLambda",
          "s3:GetBucketCORS",
          "s3:GetBucketLocation",
          "s3:GetAccessPointPolicy",
          "s3:ReplicateDelete",
          "s3:GetObjectVersion"
        ],
        "Resource" : "arn:aws:s3:::fv-dm-"
      }
    ]
  })
}
