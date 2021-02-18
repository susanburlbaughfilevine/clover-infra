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
rds-storage             = "200"
rds-max-storage         = "500"
rds-storage-type        = "gp2"
rds-instance-class      = "db.r5.large"
multi_az                = false
backup_retention_period = 5
backup_window           = "07:00-08:00"
sql_server_engine       = "sqlserver-se"
apply_immediately       = false
