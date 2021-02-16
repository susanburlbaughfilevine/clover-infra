# This is used to pass into the Octopus Environment and not restrict the ability to run 
# Terraform directly. 
# This implies using workspaces in order to deploy accordingly and not overwrite existing deployments
#
# Pattern would be 
# - Select workspace (passed in via Octopus setting or command line selection)
# - Run Terraform with a -var-file <local> or -var-file octopus.tfvars where octopus does the variable replacement

envName         = "#{Octopus.Deployment.Tenant.Name}"
region          = "#{aws_region}"
assume_role_arn = "#{aws_role}"

## Specific settings needed
#
# Add additional variables here as appropriate
#
rds-storage             = "#{sqlserver_rds_storage}"
rds-max-storage         = "#{sqlserver_rds_max_storage}"
rds-storage-type        = "#{sqlserver_rds_storage_type}"
rds-instance-class      = "#{sqlserver_rds_instance_class}"
multi_az                = #{sqlserver_rds_multi_az}
backup_retention_period = #{sqlserver_rds_backup_retention_period}
backup_window           = "#{sqlserver_rds_backup_window}"
sql_server_engine       = "#{sqlserver_engine}"
apply_immediately       = #{apply_immediately}
