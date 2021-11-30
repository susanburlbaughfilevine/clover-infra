# =======================================================================
$clover_assets        = "C:\clover_assets"
$srcBucketName        = "filevine-devops"

if (Test-Path $clover_assets) {
    Write-Output "File Path ${clover_assets} Exists"
} else {
    Write-Output "File Path ${clover_assets} Does not Exist"

    New-Item $clover_assets -ItemType directory
    # Let's create a new directory to store all of our fun scripts and stuff
    Write-Output "Creating Assets: $clover_assets"
}

Push-Location $clover_assets 

Read-S3Object -BucketName $srcBucketName -KeyPrefix cloverdx-assets/ -Folder $clover_assets -Region us-west-2
