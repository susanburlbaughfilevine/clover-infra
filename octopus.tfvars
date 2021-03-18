# This is used to pass into the Octopus Environment and not restrict the ability to run 
# Terraform directly. 
# This implies using workspaces in order to deploy accordingly and not overwrite existing deployments
#
# Pattern would be 
# - Select workspace (passed in via Octopus setting or command line selection)
# - Run Terraform with a -var-file <local> or -var-file octopus.tfvars where octopus does the variable replacement

# envName   = "#{Octopus.Environment.Name}"
# domain_name = "#{email-domain-name}"

envName                                  = "#{Octopus.Deployment.Tenant.Name}"
region                                   = "#{aws_region}"
octopus_tenant                           = "#{Octopus.Deployment.Tenant.Name}"
octopus_server_address                   = "#{octopus-server-address}"
octopus_space                            = "Metal"
octopus_api_key                          = "#{octopus-api-key}"
octopus_server_environment               = "#{Octopus.Environment.Name}"
octopus_provider_server_address          = "#{octopus-server-address}"
instance_type                            = "#{aws-ec2-instancetype}"
# ami_status                               = "#{ami_status}"
ami_status                               = "released"
# aws_role                                 = "#{aws_role}"
assume_role_arn                          = "#{aws_role}"



# aws_region                               = "#{aws_region}"


# instance_type      = "#{aws_ec2_instancetype}"

# octopus_server_environment_metal         = "Metal"
# "#{octopus-server-envrionment-metal}"
# fv_octopus_space                         = "Filevine"
#fv_devops_secret_key                     = "#{filevine_devops_secret_key}"
#fv_devops_access_key                     = "#{filevine_devops_access_key}"

# Where we last left off
# ---------------------------------
# Convert the variables below into octopus values
# * Testing the deployments
#
# * Deploy Secure patch to new client version
#
# * Copy over the Makefile from the dms_lambda_iac since we're using linux
# ---------------------------------

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
#-----------------------------------------------------------------------------
# $clover_assets        = "C:\clover_assets"
# $srcBucketName        = "filevine-devops"

# set some variables (not used)
# $cloverTomcatZip = "CloverDXServer.5.5.1.Tomcat-9.0.22.zip"
# $cloverTomcatZip   = "CloverDXServer.5.7.0.Tomcat-9.0.22.zip"
# $cloverTomcatZipDir   = "CloverDXServer.5.7.0.Tomcat-9.0.22"
# $secureCfgZip      = "secure-cfg-tool.5.6.0.zip"
# $secureCfgZip      = "secure-cfg-tool.5.7.0.zip"
# $tomcatDir            = "C:\tomcat"
# $clover_assets        = "C:\clover_assets"
# $srcBucketName        = "filevine-devops"

# $cloverTomcatZip   = "CloverDXServer.5.7.0.Tomcat-9.0.22.zip"
# $tomcatDir            = "C:\tomcat"
# $clover_assets        = "C:\clover_assets"

# Install Clover Branding

# $clover_branding_zip  = "FVBranding5.6.0.zip"
# $branding_directory   = "C:\FilevineBranding"
# $tomcatDir            = "C:\tomcat"
# $clover_assets        = "C:\clover_assets"
#-----------------------------------------------------------------------------

