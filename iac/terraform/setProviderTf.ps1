
(
    ((Get-Content -path ./provider_tf.tpl -Raw) -replace '\|PROVIDER_AWS_REGION\|', $Env:TF_VAR_provider_aws_region)
) | Set-Content -Path ./provider.tf
(
    ((Get-Content -path ./provider.tf -Raw) -replace '\|PROVIDER_S3_YEAR\|',$Env:TF_VAR_provider_s3_year)
) | Set-Content -Path ./provider.tf
(
    ((Get-Content -path ./provider.tf -Raw) -replace '\|PROVIDER_S3_MONTH\|',$Env:TF_VAR_provider_s3_month)
) | Set-Content -Path ./provider.tf
(
    ((Get-Content -path ./provider.tf -Raw) -replace '\|PROVIDER_S3_ENV\|',$Env:TF_VAR_provider_s3_environment)
) | Set-Content -Path ./provider.tf

# Get-Content -Path ./cloverServer.properties -Raw | Set-Content -Path C:\tomcat\cloverServer.properties