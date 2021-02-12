# $s3_secret_key        = $s3_secret_key
# $s3_access_key        = $s3_access_key
#Write-Output "Debug: --------------------------"
#Write-Output "S3 secret Key:  $filevine_devops_secret_key"
#Write-Output "S3 Access key:  $filevine_devops_access_key"
#Write-Output "S3 Session Key: $filevine_devops_session_token"
#Write-Output "End Debug: ----------------------"
# =======================================================================
$clover_assets        = "C:\clover_assets"
$srcBucketName        = "filevine-devops"

if (Test-Path $clover_assets) {
    Write-Output "File Path ${clover_assets} Exists"
} else {
    Write-Output "File Path ${clover_assets} Does not Exists"

    New-Item $clover_assets -ItemType directory
    # Let's create a new directory to store all of our fun scripts and stuff
    Write-Output "Creating Assets: $clover_assets"
}

Push-Location $clover_assets 

#Write-Output "Secret Key: ${filevine_devops_secret_key}"
#Write-Output "Acccess Key: ${filevine_devops_access_key}"
Set-Variable AWS_ACCESS_KEY_ID="${filevine_devops_access_key}"
Set-Variable AWS_SECRET_ACCESS_KEY="${filevine_devops_secret_key}"
Set-Variable AWS_SESSION_TOKEN="${filevine_devops_session_token}"



# FIXME: Move this stuff to Artifactory
# Let's grab our assets from S3
# Set-AWSCredentials -AccessKey "${filevine_devops_access_key}" -SecretKey "${filevine_devops_secret_key}"

# Let's verify the caller identity ...
# aws sts get-caller-identity

# $objects = Read-S3object -bucketname $srcBucketName
Read-S3Object -BucketName $srcBucketName -KeyPrefix cloverdx-assets/ -Folder $clover_assets
# Get-ChildItem $objects
