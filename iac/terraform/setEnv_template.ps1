$Env:AWS_ACCESS_KEY_ID=''
$Env:AWS_SECRET_ACCESS_KEY=''
$Env:AWS_DEFAULT_REGION=''
# $env:TF_VAR_region=us-west-2

$Env:TF_VAR_s3_access_key=''
$Env:TF_VAR_s3_secret_key=''

$Env:TF_VAR_fv_clover_rdp_password=""
$Env:TF_VAR_susan_rdp_admin_password=""
$Env:TF_VAR_bporter_rdp_admin_password=""

# Production CA Credentials
#$Env:TF_VAR_provider_s3_year=""
#$Env:TF_VAR_provider_s3_month=""
#$Env:TF_VAR_provider_s3_environment=""
#$Env:TF_VAR_provider_aws_region=""
#$Env:TF_VAR_clover_database_url=''
#$Env:TF_VAR_clover_database_db=''
#$Env:TF_VAR_clover_database_user=''
#$Env:TF_VAR_clover_database_pass=''
## Security Groups in canada
## sg-66b4310d - Import Team
## sg-d2b732b9 - Dev Wes
## sg-0341dea8e3ed6e450 - Production
# $Env:TF_VAR_security_group_ids='["sg-66b4310d","sg-d2b732b9","sg-0341dea8e3ed6e450"]'
## Subnet IDs
## subnet-91cc23f8
## subnet-ea444a92
## $Env:TF_VAR_subnet_ids='["subnet-91cc23f8","subnet-ea444a92"]'
##$Env:TF_VAR_subnet_ids='["subnet-91cc23f8"]'
#$Env:TF_VAR_subnet_ids='["subnet-ea444a92"]'
#$Env:TF_VAR_env_name="clover-prod-ca"
#$Env:TF_VAR_encryption_arn="arn:aws:kms:ca-central-1:530929067887:key/cdbf6948-10e5-47d7-950e-03f48896d27a"
