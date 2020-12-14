module "cloverdx" {
    source               = "git::ssh://git@gitlab.com/filevine/team/engineering-platform/projects.git//iac/terraform/modules/hardened_web_server"
    resource_count       = 1
    env_name             = "${var.provider_s3_environment}-cloverdx"
    instance_name_long   = "${var.provider_s3_environment}-cloverdx-test"
    instance_type        = var.instance_type
    monitoring           = "false"
    iam_instance_profile = "SSMInstanceProfile"
    security_group_ids   = var.security_group_map[var.aws_region]
    subnet_ids           = var.subnet_map[var.aws_region]
    encryption_arn       = var.encryption_map[var.aws_region]
    ami_status           = var.ami_status
    # Root Disk size should be about 200? (120 suggested min)
    template_user_data = templatefile("templates/cloverdx.tpl", {
        # Variables go here
        s3_access_key        = var.s3_access_key
        s3_secret_key        = var.s3_secret_key
        clover_database_url  = var.clover_database_url
        clover_database_db   = var.clover_database_db
        clover_database_user = var.clover_database_user
        clover_database_pass = var.clover_database_pass
        fv_clover_rdp_admin_password = "${var.fv_clover_rdp_admin_password}"
        octopus_api_key      = var.octopus_api_key
        octopus_server_address = var.octopus_server_address
        octopus_server_environment_metal = var.octopus_server_environment_metal
        octopus_server_environment = var.octopus_server_environment
        octopus_server_roles       = var.octopus_server_roles
        octopus_server_space = var.octopus_server_space 
        octopus_listen_port  = var.octopus_listen_port
        instance_name_long = "${var.provider_s3_environment}-clover"
    })
    # Root Disk size should be about 200? (120 suggested min)
    root_disk_size = 200
} 

# resource "aws_volume_attachment" "ebs_att" {
#   device_name = "/dev/xvdf"
#   volume_id   = aws_ebs_volume.instance.id
#   instance_id = element(module.cloverdx.instance_ids,0)
# }

# zone mismatch ...
# resource "aws_ebs_volume" "instance" {
#   availability_zone = "us-west-2a"
#   size              = 1
# }
