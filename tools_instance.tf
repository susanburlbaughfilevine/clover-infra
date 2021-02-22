resource "aws_route53_record" "tools_internal_record" {
  provider = aws.filevine
  zone_id  = data.aws_route53_zone.master.id
  name     = "${var.envName}-tools.${var.dns_domain}"
  type     = "CNAME"
  records        = [aws_instance.tools_instance.private_dns]
}

resource "aws_ebs_volume" "tools_instance_volume_1" {
  availability_zone = aws_instance.tools_instance.availability_zone
  size              = 3200
  kms_key_id        = "arn:aws:kms:us-west-2:608624018002:key/e793c165-23c7-495a-a112-81fd3f0ce5c8"
  encrypted         = true

  tags = {
    Name = "${var.envName}-tools-volume-1"
  }
}

resource "aws_ebs_volume" "tools_instance_volume_2" {
  availability_zone = aws_instance.tools_instance.availability_zone
  size              = 3200
  kms_key_id        = "arn:aws:kms:us-west-2:608624018002:key/e793c165-23c7-495a-a112-81fd3f0ce5c8"
  encrypted         = true

  tags = {
    Name = "${var.envName}-tools-volume-2"
  }
}

resource "aws_ebs_volume" "tools_instance_volume_3" {
  availability_zone = aws_instance.tools_instance.availability_zone
  size              = 3200
  kms_key_id        = "arn:aws:kms:us-west-2:608624018002:key/e793c165-23c7-495a-a112-81fd3f0ce5c8"
  encrypted         = true

  tags = {
    Name = "${var.envName}-tools-volume-3"
  }
}


resource "aws_instance" "tools_instance" {
  ami           = "ami-072452834855d33b9" //ami id is hardcoded due to resource import. dynamic ami would cause instance recreation
  instance_type = var.tools_instance_type
  ebs_optimized = true

  tags = {
    Name       = "${var.envName}-tools"
    managed_by = "terraform"
    env        = var.envName
  }

  vpc_security_group_ids = [data.aws_security_group.backend.id, data.aws_security_group.build.id, data.aws_security_group.techaccess.id]
  iam_instance_profile   = "${var.envName}-CloverApp-InstanceProfile"
  subnet_id              = element(tolist(data.aws_subnet_ids.private.ids), 0)
  key_name               = "dedicated-shards"

  monitoring = false

  root_block_device {
    volume_size = 200
    encrypted   = true
    kms_key_id  = "arn:aws:kms:us-west-2:608624018002:key/e793c165-23c7-495a-a112-81fd3f0ce5c8" //hardcoded to prevent instance recreation for now

  }
}

resource "aws_volume_attachment" "tools_volume_attach_1" {
  device_name = "xvdg"
  instance_id = aws_instance.tools_instance.id
  volume_id   = aws_ebs_volume.tools_instance_volume_2.id
}

resource "aws_volume_attachment" "tools_volume_attach_2" {
  device_name = "xvdh"
  instance_id = aws_instance.tools_instance.id
  volume_id   = aws_ebs_volume.tools_instance_volume_3.id
}

resource "aws_volume_attachment" "tools_volume_attach_3" {
  device_name = "xvdj"
  instance_id = aws_instance.tools_instance.id
  volume_id   = aws_ebs_volume.tools_instance_volume_1.id
}