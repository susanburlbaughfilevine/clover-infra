resource "aws_instance" "clover" {
  count         = 1
  ami           = data.aws_ami.windows.id
  instance_type = var.instance_type

  tags = {
    Name       = "${var.envName}-clover-${count.index}"
    managed_by = "terraform"
    env        = var.envName
  }

  vpc_security_group_ids = [
    data.aws_security_group.backend.id,
    data.aws_security_group.build.id,
    data.aws_security_group.techaccess.id,
    data.aws_security_group.dataaccess.id
  ]

  iam_instance_profile = "${var.envName}-CloverApp-InstanceProfile"
  subnet_id            = element(tolist(data.aws_subnet_ids.private.ids), count.index)
  key_name             = "dedicated-shards"
  user_data = templatefile("${path.module}/templates/userdata.ps1", {

    octopus_api_key            = var.octopus_api_key
    octopus_server_address     = var.octopus_server_address
    octopus_space              = var.octopus_space
    octopus_server_environment = var.octopus_server_environment
    octopus_tenant             = var.octopus_tenant
    server_roles               = "clover-server"
    scaleft_config             = file("${path.root}/sftd.yaml")
  })
  monitoring = false

  root_block_device {
    volume_size = 200
    encrypted   = true
    kms_key_id  = data.aws_kms_alias.backend.target_key_arn
  }
}
