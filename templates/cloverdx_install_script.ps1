# set some variables (not used)
# $s3_secret_key        = ""
# $s3_access_key        = ""
# $clover_database_url  = ""
# $clover_database_user = ""
# $clover_database_pass = ""
# $clover_database_db   = ""
# =======================================================================
# $cloverTomcatZip = "CloverDXServer.5.5.1.Tomcat-9.0.22.zip"
$cloverTomcatZip      = "CloverDXServer.5.7.0.Tomcat-9.0.22.zip"
$tomcatDir            = "C:\tomcat"
$clover_assets        = "C:\clover_assets"
$srcBucketName        = "filevine-devops"

# #######################################################################
# This is used as the powershell script that is implemented in octopus
# The idea is that the update will let you spin up the base server
# and the install script can be used to update the redpepper clover server
# as well as the separate clover systems
# #######################################################################
# Start the timer
$userdata_start_time = Get-Date
Write-Output("Start Time: $userdata_start_time")

# Unzip Function
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function setUserWritablePermissions
{

    param([string]$filepath)

    # -- Set the permissions for the file
    $user = "Users" #User account to grant permisions too.
    $Rights = "Write, Read, ReadAndExecute" # Comma seperated list.
    $PropogationSettings = "None" #Usually set to none but can setup rules that only apply to children.
    $RuleType = "Allow" #Allow or Deny.

    $acl = Get-Acl $filepath
    $perm = $user, $Rights, $RuleType
    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
    $acl.SetAccessRule($rule)
    $acl | Set-Acl -Path $filepath
    # The file needs to be writeable
    Write-Output "permissions updated for $filepath file"
}

function addAdminUser
{
    param([string]$username, [string]$password, [string]$fullname, [string]$description)
    $UserPassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser $username -Password $UserPassword -FullName $fullname -Description $description
    Add-LocalGroupMember -Group 'Administrators' -Member ($username) –Verbose
}

function addNormalUser
{
    param([string]$username, [string]$password, [string]$fullname, [string]$description)
    $UserPassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser $username -Password $UserPassword -FullName $fullname -Description $description
    Add-LocalGroupMember -Group 'Users' -Member ($username) –Verbose
}


New-Item $clover_assets -ItemType directory
# Let's create a new directory to store all of our fun scripts and stuff
Write-Output "Creating Assets: $clover_assets"

Push-Location $clover_assets 

# FIXME: Move this stuff to Artifactory
# Let's grab our assets from S3
# Set-AWSCredentials –AccessKey $s3_access_key -SecretKey $s3_secret_key

# $objects = get-S3object -bucketname $srcBucketName
# Read-S3Object -BucketName $srcBucketName -KeyPrefix cloverdx-assets/ -Folder $clover_assets


# Creating a directory for tomcat
# New-Item $tomcatDir -ItemType directory


# -------------
# FIXME: We should be download the assets from a trusted resource (artifactory)
# -------------

# unzip $clover_assets\CloverDXServer.5.5.1.Tomcat-9.0.22.zip $tomcatDir
# unzip $clover_assets\$cloverTomcatZip $tomcatDir

# Push-Location $clover_assets 

# - setCloverServerProperties.ps1
# (This will create a file in $tomcatDir)
# ./setCloverServerProperties.ps1 -Database_url $clover_database_url -Database_db $clover_database_db -Database_user $clover_database_user -Database_pass "$clover_database_pass"
# Write-Output "Created clover-server.properties file"

# -- Set the permissions for the file
# setUserWritablePermissions "$tomcatDir/cloverServer.properties"

# We should also move the profiler.properties file
# Copy-Item -Path $clover_assets\profilerServer.properties -Destination $tomcatDir/profilerServer.properties
# Write-Output "copied profilerServer.properties file"
# setUserWritablePermissions "$tomcatDir/profilerServer.properties"

# Install JDK
# Push-Location $clover_assets 
# Write-Output "Unzip JDK"
# Unzip "$clover_assets\jdk-11.win.x64.zip" "c:\jdk-11\"
# JDK 11: C:\jdk-11\jdk-11.0.6+10

# FIXME This will be a very brittle design ...
# Should grab the newest (only) item in the Folder
# grab the only folder in this directory ...
# $jdkDirectory = gci C:\jdk-11\ | ? { $_.PSIsContainer } | sort CreationTime -desc | select -f 1
# Write-Output "Grab latest jdk directory"

# I set this in pairs, so that the userdata script has access to these
# instead of waiting to have to reload
# $env:JAVA_HOME = "C:\Program Files\Java\jdk1.8.0_241";
# $env:JAVA_HOME = "C:\jdk-11\$jdkDirectory";
# [Environment]::SetEnvironmentVariable("JAVA_HOME", "$env:JAVA_HOME", "Machine")
# $env:JRE_HOME = "$env:JAVA_HOME";
# [Environment]::SetEnvironmentVariable("JRE_HOME", "$env:JRE_HOME", "Machine")
# [Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:JAVA_HOME\bin", "Machine")
# $env:Path += "$env:Path;$env:JAVA_HOME\bin";
# Write-Output "Environment variables updated"

# Install Tomcat
# "c:/cloverdx_assets/"
# $cloverdx_assets = "C:\cloverdx_assets\"

# Installation Complete
Write-Output "Userdata - Time taken: $((Get-Date).Subtract($userdata_start_time).Seconds) second(s)"
Write-Output("End Time: $(Get-Date)")
