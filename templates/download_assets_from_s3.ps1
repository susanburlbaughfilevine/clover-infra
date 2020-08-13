$s3_secret_key        = ""
$s3_access_key        = ""
# =======================================================================
$clover_assets        = "C:\clover_assets"
$srcBucketName        = "filevine-devops"

New-Item $clover_assets -ItemType directory
# Let's create a new directory to store all of our fun scripts and stuff
Write-Output "Creating Assets: $clover_assets"

Push-Location $clover_assets 

# FIXME: Move this stuff to Artifactory
# Let's grab our assets from S3
Set-AWSCredentials –AccessKey $s3_access_key -SecretKey $s3_secret_key

$objects = get-S3object -bucketname $srcBucketName
Read-S3Object -BucketName $srcBucketName -KeyPrefix cloverdx-assets/ -Folder $clover_assets
