# This is used to pass into the Octopus Environment and not restrict the ability to run 
# Terraform directly. 
# This implies using workspaces in order to deploy accordingly and not overwrite existing deployments
#
# Pattern would be 
# - Select workspace (passed in via Octopus setting or command line selection)
# - Run Terraform with a -var-file <local> or -var-file octopus.tfvars where octopus does the variable replacement

# envName   = "#{Octopus.Environment.Name}"
# domain_name = "#{email-domain-name}"
aws_region = "us-west-2"

octopus_server_address           = "http://172.31.10.85:88"
octopus_api_key                  = ""
octopus_server_environment_metal = "Metal"
octopus_space                    = "Metal"
octopus_server_environment       = "test"
octopus_provider_server_address  = "http://172.31.10.85:88"

instance_type = "t2.micro"

fv_clover_rdp_admin_password = "whatIsTheDefaultPasswordLength?"
bporter_rdp_admin_password   = "whereOhWHereHaveWeAllGone?"
susan_rdp_admin_password     = "RemoveEveryoneWhoSHouldNotBeHere"
dave_rdp_admin_password      = "WRASHW23sdkei"
clover_database_db           = ""
clover_database_url          = ""
clover_database_user         = ""
env_name                     = "test"
s3_access_key                = ""
s3_secret_key                = ""
# Not Canada Servers
