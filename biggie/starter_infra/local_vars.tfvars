# account_id                       = "926927448710"
# assume_role_arn                  = "926927448710"
envName                          = "team-fva"
region                           = "us-west-2"
#octopus_tenant                   = "team-fva"
#octopus_server_address           = "http://internal-octopus.filevinedev.com:88"
# octopus_server_address           = "https://172.31.10.85:88"
#octopus_space                    = "Metal"
#octopus_api_key                  = "API-WE6B3RGXLQFGONBCB2GHDJQOG44"
# octopus_server_environment_metal = "Metal"
# fv_octopus_space                 = "Filevine"
#octopus_server_environment       = "Tenant-QA"

#octopus_provider_server_address  = "internal-octopus.filevinedev.com:88"
# octopus_provider_server_address  = "https://172.31.10.85"
#instance_type                    = "t2.micro"
# scaleft_uri                    = ""
#ami_status                       = "released"
# aws_role                         = "arn:aws:iam::926927448710:role/Terraform"
assume_role_arn                         = "arn:aws:iam::926927448710:role/Terraform"

# Add additional variables here as appropriate
dns_domain = "filevinedev.com"
subdomain  = "cloverdx-team-fva"

# Node.js Variables for Slack Alert Lambda Function
slack_channel_name = "team-fva"
slack_webhook      = ""
