module "gp3_matrix_ec2" {
  source                       = "git::ssh://git@gitlab.com/filevine/technology/project/terraform-modules/module-aws-gp3-matrix.git?ref=v0.1.7"
  storage_performance_category = "ec2-standard"
  storage_throughput           = null
  storage_iops                 = null
  storage_size                 = var.ec2_storage_size
  storage_type                 = var.ec2_storage_type
}


module "gp3_matrix_ebs_lun" {
  source                       = "git::ssh://git@gitlab.com/filevine/technology/project/terraform-modules/module-aws-gp3-matrix.git?ref=v0.1.7"
  storage_performance_category = "ec2-standard"
  storage_throughput           = null
  storage_iops                 = null
  storage_size                 = var.ebs_lun_storage_size
  storage_type                 = var.ebs_lun_storage_type
}
