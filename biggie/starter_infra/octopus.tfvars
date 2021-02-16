# This is used to pass into the Octopus Environment and not restrict the ability to run 
# Terraform directly. 
# This implies using workspaces in order to deploy accordingly and not overwrite existing deployments
#
# Pattern would be 
# - Select workspace (passed in via Octopus setting or command line selection)
# - Run Terraform with a -var-file <local> or -var-file octopus.tfvars where octopus does the variable replacement

envName         = "#{Octopus.Deployment.Tenant.Name}"
assume_role_arn = "#{aws_role}"

## Specific settings needed
#
# Add additional variables here as appropriate
dns_domain = "#{dns_domain}"
subdomain  = "#{subdomain}"

# Node.js Variables for Slack Alert Lambda Function
slack_channel_name = "#{slack_channel_name}"
slack_webhook      = "#{slack_webhook}"
