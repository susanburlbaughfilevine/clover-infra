envName             = "#{Octopus.Deployment.Tenant.Name}"
region              = "#{aws_region}"
dns_domain          = "#{dns_domain}"
subdomain           = "#{subdomain}"
shorturl_dns_domain = "#{shorturl_dns_domain}"
clover_domain       = "#{clover_domain}"

octopus_tenant                  = "#{Octopus.Deployment.Tenant.Name}"
octopus_space                   = "#{Octopus.Space.Name}"
octopus_api_key                 = "#{octopus-api-key}"
octopus_server_environment      = "#{Octopus.Environment.Name}"
octopus_server_address          = "#{octopus-server-address}"
octopus_provider_server_address = "#{octopus-server-address}"
instance_type                   = "#{aws-ec2-instancetype}"
ami_status                      = "released"
aws_role                        = "#{aws_role}"
assume_role_arn                 = "#{aws_role}"

rds_storage        = "#{rds_storage}"
rds_max_storage    = "#{rds_max_storage}"
rds_storage_type   = "#{rds_storage_type}"
rds_engine         = "#{rds_engine}"
rds_engine_version = "#{rds_engine_version}"
rds_instance_class = "#{rds_instance_class}"
rds_user_name      = "#{rds_user_name}"
rds_user_password  = "#{rds_user_password}"
