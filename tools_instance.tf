resource "aws_ebs_volume" "tools_instance_volume_1" {
  availability_zone = aws_instance.tools_instance.availability_zone
  size              = 3200
  kms_key_id        = data.aws_kms_alias.backend.target_key_arn
  encrypted         = true

  tags = {
    Name = "${var.envName}-tools-volume-1"
  }
}

resource "aws_ebs_volume" "tools_instance_volume_2" {
  availability_zone = aws_instance.tools_instance.availability_zone
  size              = 3200
  kms_key_id        = data.aws_kms_alias.backend.target_key_arn
  encrypted         = true

  tags = {
    Name = "${var.envName}-tools-volume-2"
  }
}

resource "aws_ebs_volume" "tools_instance_volume_3" {
  availability_zone = aws_instance.tools_instance.availability_zone
  size              = 3200
  kms_key_id        = data.aws_kms_alias.backend.target_key_arn
  encrypted         = true

  tags = {
    Name = "${var.envName}-tools-volume-3"
  }
}


resource "aws_instance" "tools_instance" {
  ami           = data.aws_ami.windows.id
  instance_type = var.tools_instance_type

  tags = {
    Name       = "${var.envName}-tools"
    managed_by = "terraform"
    env        = var.envName
  }

  vpc_security_group_ids = [data.aws_security_group.backend.id, data.aws_security_group.build.id, data.aws_security_group.techaccess.id]
  iam_instance_profile   = "${var.envName}-CloverApp-InstanceProfile"
  subnet_id              = element(tolist(data.aws_subnet_ids.private.ids), 0)
  key_name               = "dedicated-shards"

  user_data = templatefile("${path.root}/userdata.ps1", {
    octopus_api_key = var.octopus_api_key
    # Need to shift this to HTTPS
    octopus_server_address     = var.octopus_server_address
    octopus_space              = var.octopus_space
    octopus_server_environment = var.octopus_server_environment
    octopus_tenant             = var.octopus_tenant
    server_roles               = "tools"
    scaleft_config             = "${file("${path.root}/sftd.yaml")}"
  })

  monitoring = false

  root_block_device {
    volume_size = 200
    encrypted   = true
    kms_key_id  = data.aws_kms_alias.backend.target_key_arn
  }
}

resource "aws_volume_attachment" "tools_volume_attach_1" {
  device_name = "xvdg"
  instance_id = aws_instance.tools_instance.id
  volume_id   = aws_ebs_volume.tools_instance_volume_1.id
}

resource "aws_volume_attachment" "tools_volume_attach_2" {
  device_name = "xvdh"
  instance_id = aws_instance.tools_instance.id
  volume_id   = aws_ebs_volume.tools_instance_volume_2.id
}

resource "aws_volume_attachment" "tools_volume_attach_3" {
  device_name = "xvdj"
  instance_id = aws_instance.tools_instance.id
  volume_id   = aws_ebs_volume.tools_instance_volume_3.id
}