# $s3_secret_key        = $s3_secret_key
# $s3_access_key        = $s3_access_key
Write-Output "Debug: ----------------------"
Write-Output "S3 secret Key: $s3_secret_key"
Write-Output "S3 Access key: $s3_access_key"
Write-Output "End Debug: ----------------------"
# =======================================================================
$clover_assets        = "C:\clover_assets"
$srcBucketName        = "filevine-devops"

New-Item $clover_assets -ItemType directory
# Let's create a new directory to store all of our fun scripts and stuff
Write-Output "Creating Assets: $clover_assets"

Push-Location $clover_assets 

Write-Output "Secret Key: ${s3_secret_key}"
Write-Output "Acccess Key: ${s3_access_key}"

# FIXME: Move this stuff to Artifactory
# Let's grab our assets from S3
Set-AWSCredentials –AccessKey $s3_access_key -SecretKey $s3_secret_key

$objects = get-S3object -bucketname $srcBucketName
Read-S3Object -BucketName $srcBucketName -KeyPrefix cloverdx-assets/ -Folder $clover_assets
