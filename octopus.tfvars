# This is used to pass into the Octopus Environment and not restrict the ability to run 
# Terraform directly. 
# This implies using workspaces in order to deploy accordingly and not overwrite existing deployments
#
# Pattern would be 
# - Select workspace (passed in via Octopus setting or command line selection)
# - Run Terraform with a -var-file <local> or -var-file octopus.tfvars where octopus does the variable replacement

# envName   = "#{Octopus.Environment.Name}"
# domain_name = "#{email-domain-name}"
# aws_region      = "#{aws-region}"

aws_role = "#{aws_role}"

envName         = "#{Octopus.Deployment.Tenant.Name}"
region          = "#{aws_region}"

octopus_tenant                  = "#{Octopus.Deployment.Tenant.Name}"


# instance_type      = "#{aws_ec2_instancetype}"

octopus_server_address = "#{octopus-server-address}"
octopus_api_key = "#{octopus-api-key}"
octopus_server_environment_metal = "Metal" # "#{octopus-server-envrionment-metal}"
octopus_space = "Metal"
fv_octopus_space = "Filevine"
octopus_server_environment = "#{Octopus.Environment.Name}"
octopus_provider_server_address = "#{octopus-server-address}"

instance_type = "#{aws-ec2-instancetype}"

scaleft_uri   = "#{scaleft_uri}"


ami_status              = "#{ami_status}"

#fv_clover_rdp_admin_password = "#{fv_clover_rdp_admin_password}"
#bporter_rdp_admin_password="#{bporter_rdp_admin_password}"      
#susan_rdp_admin_password="#{susan_rdp_admin_password}"          
#dave_rdp_admin_password="#{dave_rdp_admin_password}"            
#clover_database_db="#{clover_database_db}"
#clover_database_url="#{clover_database_url}"
#clover_database_user="#{clover_database_user}"
#env_name="#{env_name}"
#s3_access_key="#{s3_access_key}" 
#s3_secret_key="#{s3_secret_key}" 
# Not Canada Servers
