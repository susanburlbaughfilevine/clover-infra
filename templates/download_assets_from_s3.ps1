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


Read-S3Object -BucketName $srcBucketName -KeyPrefix cloverdx-assets/ -Folder $clover_assets -AccessKey $filevine_devops_access_key -SecretKey $filevine_devops_secret_key -SessionToken $filevine_devops_session_token -Region us-west-2
# Read-S3Object -BucketName $srcBucketName -KeyPrefix cloverdx-assets/ -Folder $clover_assets -AccessKey $AWS_ACCESS_KEY_ID -SecretKey $AWS_SECRET_ACCESS_KEY -SessionToken $AWS_SESSION_TOKEN -Region us-west-2
