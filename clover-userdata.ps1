<powershell>

$clover_assets        = "C:\clover_assets"
$srcBucketName        = "filevine-devops"

# set some variables (not used)
# $cloverTomcatZip = "CloverDXServer.5.5.1.Tomcat-9.0.22.zip"
$cloverTomcatZip   = "CloverDXServer.5.7.0.Tomcat-9.0.22.zip"
$cloverTomcatZipDir   = "CloverDXServer.5.7.0.Tomcat-9.0.22"
# $secureCfgZip      = "secure-cfg-tool.5.6.0.zip"
$secureCfgZip      = "secure-cfg-tool.5.7.0.zip"
$tomcatDir            = "C:\tomcat"
$clover_assets        = "C:\clover_assets"
$srcBucketName        = "filevine-devops"

$cloverTomcatZip   = "CloverDXServer.5.7.0.Tomcat-9.0.22.zip"
$tomcatDir            = "C:\tomcat"
$clover_assets        = "C:\clover_assets"

# Install Clover Branding

$clover_branding_zip  = "FVBranding5.6.0.zip"
$branding_directory   = "C:\FilevineBranding"
$tomcatDir            = "C:\tomcat"
$clover_assets        = "C:\clover_assets"

# ------------------------------------------------------------

$userdata_start_time = Get-Date

$folder = "c:\dsc\config"


# How do you get the Private IP that is generated from the EC2 Instance?
# Hit the metadata server for info
$ipv4 = (Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/local-ipv4 -UseBasicParsing).Content
$instanceId = (Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing).Content

# Get the value of the 'Name' Tag
# Requires Role Policy ec2DescribeTags
$instanceName = ((Get-EC2Instance -InstanceId $instanceId).Instances[0].Tag | ? {$_.key -eq 'Name'}).Value

Write-Output "ipv4: $ipv4"

# Things to execute before DSC things
# ----------------------------------------------------------------------------------

# -----------------------------------
# S3 Assets from Filevine Devops
# -----------------------------------
New-Item $clover_assets -ItemType directory
# Let's create a new directory to store all of our fun scripts and stuff
Write-Output "Creating Assets: $clover_assets"

Push-Location $clover_assets 

# FIXME: Move this stuff to Artifactory
# Let's grab our assets from S3
Set-AWSCredentials –AccessKey $filevine_devops_access_key -SecretKey $filevine_devops_secret_key

$objects = get-S3object -bucketname $srcBucketName
Read-S3Object -BucketName $srcBucketName -KeyPrefix cloverdx-assets/ -Folder $clover_assets

# -----------------------------------
# Deploy Clover to System
# -----------------------------------

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

# Creating a directory for tomcat
New-Item $tomcatDir -ItemType directory

Push-Location $clover_assets 

# unzip $clover_assets\CloverDXServer.5.5.1.Tomcat-9.0.22.zip $tomcatDir
unzip $clover_assets\$cloverTomcatZip $tomcatDir


# --------------------------------------------------------------------
# - setCloverServerProperties.ps1
# (This will create a file in $tomcatDir)
#./setCloverServerProperties.ps1 -Database_url $clover_database_url -Database_db $clover_database_db -Database_user $clover_database_user -Database_pass "$clover_database_pass"
# Write-Output "Created clover-server.properties file"

# -- Set the permissions for the file
#setUserWritablePermissions "$tomcatDir/cloverServer.properties"

# We should also move the profiler.properties file
#Copy-Item -Path $clover_assets\profilerServer.properties -Destination $tomcatDir/profilerServer.properties
#Write-Output "copied profilerServer.properties file"
#setUserWritablePermissions "$tomcatDir/profilerServer.properties"
# --------------------------------------------------------------------

# -------------
# FIXME: We should be download the assets from a trusted resource (artifactory)
# -------------


# Install JDK
# Push-Location $clover_assets 
Write-Output "Unzip JDK"
Unzip "$clover_assets\jdk-11.win.x64.zip" "c:\jdk-11\"
# JDK 11: C:\jdk-11\jdk-11.0.6+10

# FIXME This will be a very brittle design ...
# Should grab the newest (only) item in the Folder
# grab the only folder in this directory ...
$jdkDirectory = gci C:\jdk-11\ | ? { $_.PSIsContainer } | sort CreationTime -desc | select -f 1
Write-Output "Grab latest jdk directory"

# I set this in pairs, so that the userdata script has access to these
# instead of waiting to have to reload
# $env:JAVA_HOME = "C:\Program Files\Java\jdk1.8.0_241";
$env:JAVA_HOME = "C:\jdk-11\$jdkDirectory";
[Environment]::SetEnvironmentVariable("JAVA_HOME", "$env:JAVA_HOME", "Machine")
$env:JRE_HOME = "$env:JAVA_HOME";
[Environment]::SetEnvironmentVariable("JRE_HOME", "$env:JRE_HOME", "Machine")
[Environment]::SetEnvironmentVariable("Path", "$env:Path;$env:JAVA_HOME\bin", "Machine")
$env:Path += "$env:Path;$env:JAVA_HOME\bin";
Write-Output "Environment variables updated"

# Unzip Tomcat
## Path: C:\tomcat\v9\apache-tomcat-9.0.30\bin
Unzip "$clover_assets\apache-tomcat-win.x64.zip" "c:\tomcat\v9\"
Write-Output "unzip tomcat"

# grab the only folder in this directory ...
$tomcatWeb = gci C:\tomcat\v9\ | ? { $_.PSIsContainer } | sort CreationTime -desc | select -f 1
Write-Output "grab tomcat version directory"

$tomcatDirectory = "C:\tomcat\v9\$tomcatWeb"

# Push-Location $tomcatDirectory\bin

# Move the ROOT application / replace webapps directory
Push-Location $tomcatDirectory
Move-Item $tomcatDirectory\webapps $tomcatDirectory\webapps.old

Write-Output "Update webapps in tomcat"

# We have started from a fresh new directory
New-Item $tomcatDirectory\webapps -ItemType directory
# New-Item $tomcatDirectory\webapps\ROOT -ItemType directory


# move cloverdx.war into tomcat webapp directory (so it can start the application) / Unwar cloverdx war as the ROOT application

$start_time = Get-Date
Unzip "$clover_assets\ROOT.zip" "$tomcatDirectory\webapps\"
Push-Location $tomcatDirectory\webapps

# We want to copy the clover.war to the current directory
New-Item $tomcatDirectory\webapps\clover -ItemType directory

# This is where I was messing up
# grab the only folder in this directory ...
$new_clover_assets = "$tomcatDir\$cloverTomcatZipDir\webapps\"
# C:\tomcat\CloverDXServer.5.7.0.Tomcat-9.0.22\webapps
Copy-Item -Path $new_clover_assets\clover.war -Destination $tomcatDirectory\webapps\clover\clover.war
New-Item $tomcatDirectory\webapps\profiler -ItemType directory
Copy-Item -Path $new_clover_assets\profiler.war -Destination $tomcatDirectory\webapps\profiler\profiler.war

# Copy-Item -Path $clover_assets\ROOT.zip -Destination $tomcatDirectory\webapps\
Write-Output "copy clover.war to webapps"
Write-Output "Clover clover.war moved to webapps - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"


$start_time = Get-Date
Push-Location $tomcatDirectory\webapps\clover
jar -xvf clover.war
Write-Output "clover.war extracted"
Push-Location $tomcatDirectory\webapps\profiler
jar -xvf profiler.war
Write-Output "profiler.war extracted"

Write-Output "Clover Extracted - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# Update the library (add in the mssql drivers)
$start_time = Get-Date
Copy-Item -Path $clover_assets\mssql-jdbc-7.4.1.jre11.jar -Destination $tomcatDirectory\webapps\clover\WEB-INF\lib\mssql-jdbc-7.4.1.jre11.jar
# Move-Item $clover_assets\mssql-jdbc-7.4.1.jre11.jar $tomcatDirectory\webapps\clover\WEB-INF\lib\mssql-jdbc-7.4.1.jre11.jar
Copy-Item -Path $clover_assets\mssql-jdbc-7.4.1.jre11-shaded.jar -Destination $tomcatDirectory\webapps\clover\WEB-INF\lib\mssql-jdbc-7.4.1.jre11-shaded.jar
# Move-Item $clover_assets\mssql-jdbc-7.4.1.jre11-shaded.jar $tomcatDirectory\webapps\clover\WEB-INF\lib\mssql-jdbc-7.4.1.jre11-shaded.jar
Copy-Item -Path $clover_assets\mssql-jdbc-8.2.2.jre11.jar -Destination $tomcatDirectory\webapps\clover\WEB-INF\lib\mssql-jdbc-8.2.2.jre11.jar
Write-Output "Move Files (mssql) - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "MSSQL lib files added"

# Install Bouncey Castle - Encryption
# Copy files from S3 assets directory
$start_time = Get-Date
Copy-Item -Path $clover_assets\bcprov-jdk15on-165.jar -Destination $tomcatDirectory\webapps\clover\WEB-INF\lib\bcprov-jdk15on-165.jar

Unzip "$clover_assets\$secureCfgZip" "$clover_assets\secure-cfg\"

Copy-Item -Path $clover_assets\secure-cfg\secure-cfg-tool\lib\jasypt-1.9.0.jar -Destination $tomcatDirectory\webapps\clover\WEB-INF\lib\jasypt-1.9.0.jar
Write-Output "Move Files (lib files) - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "Updated encryption lib files for clover"

# Copy over conf file (server.xml)
# This allows us to host on port 80
$start_time = Get-Date
Move-Item $tomcatDirectory\conf\server.xml $tomcatDirectory\conf\server.xml.old
Copy-Item -Path $clover_assets\clover-server.xml -Destination $tomcatDirectory\conf\server.xml
Write-Output "Move Files (server.xml) - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "Updated server.xml file for clover (port 80)"

# Stop IIS so we can free up port 80
$start_time = Get-Date
Write-Output "Stop IIS"
$serviceName = "World Wide Web Publishing Service"
# We need to disable the IIS service so when we restart the machine, it doesn't start up
# Set-Service $serviceName -StartupType Disabled
Stop-Service -Name $serviceName
Write-Output "Stop IIS - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# FIXME - No Service found
Write-Output "Start Service Apache Tomcat / Clover"
$start_time = Get-Date
$serviceName = "Apache Tomcat 9.0 Tomcat9"
Start-Service -Name $serviceName
Write-Output "start tomcat - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "start tomcat service"

# Update Firewall on server
$start_time = Get-Date
New-NetFirewallRule -DisplayName "Apache Commons Daemon Service Manager" -Direction Inbound -Program "$tomcatDirectory\bin\Tomcat9w.exe" -Action Allow
New-NetFirewallRule -DisplayName "Apache Commons Daemon Service Runner" -Direction Inbound -Program "$tomcatDirectory\bin\Tomcat9.exe" -Action Allow
# We need to open ports for SMTP, JDBC, MX, http, https, imap/pop3, ftp/sftp/ftps (what ports are these?)
# New-NetFirewallRule -DisplayName "Block Outbound Port 80" -Direction Outbound -LocalPort 80 -Protocol TCP -Action Block

Write-Output "Firewall - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "Firewall has been updated"

Write-Output "Please stop the IIS Service manually (set to disabled)"

# ----------------------------------------

# ----------------------------------------
# Creating a directory for tomcat
# New-Item $tomcatDir -ItemType directory


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


Push-Location $clover_assets 


# - setCloverServerProperties.ps1
# (This will create a file in $tomcatDir)
./setCloverServerProperties.ps1 -Database_url $clover_database_url -Database_db $clover_database_db -Database_user $clover_database_user -Database_pass "$clover_database_pass"
Write-Output "Created clover-server.properties file"

# -- Set the permissions for the file
setUserWritablePermissions "$tomcatDir/cloverServer.properties"

# We should also move the profiler.properties file
Copy-Item -Path $clover_assets\profilerServer.properties -Destination $tomcatDir/profilerServer.properties
Write-Output "copied profilerServer.properties file"
setUserWritablePermissions "$tomcatDir/profilerServer.properties"



# grab the only folder in this directory ...
$tomcatWeb = gci C:\tomcat\v9\ | ? { $_.PSIsContainer } | sort CreationTime -desc | select -f 1
Write-Output "grab tomcat version directory"

$tomcatDirectory = "C:\tomcat\v9\$tomcatWeb"

# start up Tomcat
$start_time = Get-Date
Copy-Item -Path $clover_assets\clover-setup.bat -Destination $tomcatDirectory\bin\clover-setup.bat
Write-Output "Copy clover-setup.bat"


Push-Location $tomcatDirectory\bin
# Push-Location $tomcatDir\bin
.\clover-setup.bat
Write-Output "Install Tomcat Service - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "execute clover-setup.bat"


# ----------------------------------------------------------
# Restart Tomcat
# ----------------------------------------------------------
# Windows Service - Kill & Start

$serviceName = "Tomcat9"
$processName = "Tomcat9.exe"

Write-Output "Killing Process of $serviceName..."

Get-Process | Where-Object { $_.Name -eq $processName } | Select-Object -First 1 | Stop-Process -Force

Write-Output "Sleeping for five seconds after killing of process $processName..."

Start-Sleep 5

Write-Output "Starting Service $serviceName..."

Start-Service -Name $serviceName

Write-Output "Sleeping for ten seconds after starting of Service $serviceName..."
Start-Sleep 10

Write-Output "Getting status of Service $serviceName..."

Get-Service -Name $serviceName | FL

# ---------------------------------------------------------
# Apply Branding
# ---------------------------------------------------------

# --------------------------------------------------------------------
# Unzip Function
# Add-Type -AssemblyName System.IO.Compression.FileSystem
# function Unzip
# {
#       param([string]$zipfile, [string]$outpath)
# 
#           [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
# }
# --------------------------------------------------------------------

# Creating a directory for FilevineBranding 
New-Item $branding_directory -ItemType directory

unzip $clover_assets\$clover_branding_zip $branding_directory

# grab the only folder in this directory ...
$tomcatWeb = gci C:\tomcat\v9\ | ? { $_.PSIsContainer } | sort CreationTime -desc | select -f 1
Write-Output "grab tomcat version directory"

$tomcatDirectory = "C:\tomcat\v9\$tomcatWeb"

# Copy FV Branding Zip to tomcat directory
Copy-Item -Path $clover_assets\$clover_branding_zip -Destination $tomcatDir/$clover_branding_zip

# Push-Location $tomcatDirectory\webapps\clover

# Move the ROOT application / replace webapps directory
# Push-Location $tomcatDirectory

# https://doc.cloverdx.com/latest/server/data-apps-branding.html




# ----------------------------------------------------------------------------------


# Define a configuration to allow reboot and resume behavior in DSC
[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node "localhost"
    {
        Settings
        {
            RebootNodeIfNeeded = $True
        }
    }
}


# Define a configuration to install Octopus tentacle
# Can be compiled and applied as follows:
# InstallOctopus -ComputerName "<desired Octopus Display Name here>"
# Start-DscConfiguration -Path .\InstallOctopus\ -Verbose -Wait -Force
Configuration InstallOctopus
{
    param
    (
        [String]
        $ComputerName=$(hostname)
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'OctopusDSC'
    
    cTentacleAgent OctopusTentacle
    {
        Ensure = "Present"
        State = "Started"
        # Tentacle instance name. Leave it as 'Tentacle' unless you have more
        # than one instance
        Name = "Tentacle"
        # Use internal comms
        DisplayName = "$ComputerName"
        PublicHostNameConfiguration = "Custom"
        CustomPublicHostName = "$ipv4"
        # Configure project space
        Space = "${octopus_space}"
        # Registration - all parameters required
        ApiKey = "${octopus_api_key}"
        OctopusServerUrl = "${octopus_server_address}"
        Environments = "${octopus_server_environment}"
        Tenants = "${octopus_tenant}"
        Roles = "${server_roles}"
    }
}

# Don't use the Default RenameComputer DSC as of 3 Mar 2020 as it limits to 15 char password
# Default to setting the compiled configuration to current computer name.  Pass a name in to change it.
Configuration ScriptRenameComputer
{
    param
    (
        [String]
        $NewComputerName = $env:COMPUTERNAME
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'

    Node localhost
    {
        Script RenameComputerScript
        {
            SetScript = { 
                Write-Verbose "Setting the name to $using:NewComputerName"
                Rename-Computer -NewName "$using:NewComputerName" -Force 
            }
            TestScript = { 
                Write-Verbose "Checking if $using:NewComputerName matches $env:COMPUTERNAME"
                $using:NewComputerName -match $env:COMPUTERNAME 
            }
            GetScript = { @{ Result = ($env:COMPUTERNAME) } }
        }

        PendingReboot AfterRenameComputer {
            Name = 'AfterRenameComputer'
            DependsOn = '[Script]RenameComputerScript'
        }
    }
}

Install-Module xPsDesiredStateConfiguration -Force -Verbose

Configuration InstallScaleFT
{
    Import-DscResource -ModuleName 'xPsDesiredStateConfiguration'
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    xRemoteFile ScaleFTDownload
    {
        Uri             = "https://dist.scaleft.com/server-tools/windows/v1.49.2/ScaleFT-Server-Tools-1.49.2.msi"
        DestinationPath = "$($env:SystemRoot)\Temp\scaleft.msi"
    }

    File ScaleFTDirectory
    {
        Type = 'Directory'
        DestinationPath = 'c:\windows\System32\config\systemprofile\AppData\Local\ScaleFT\'
        Ensure = "Present"
    }

    File ScaleFTConfig
    {
        DestinationPath = "C:\windows\System32\config\systemprofile\AppData\Local\ScaleFT\sftd.yaml"
        Ensure = "Present"
        Contents   = "${scaleft_config}"
    }

    Package ScaleFTInstall
    {
        Ensure    = "Present"
        Name      = "ScaleFT Server Tools"
        Path      = "$($env:SystemRoot)\Temp\scaleft.msi"
        DependsOn = '[xRemoteFile]ScaleFTDownload'
        Arguments = "/qn"
        ProductId = "C7306BF4-1BA4-45BF-B557-F96D793BAA00"
        ReturnCode = 0
    }
}

# Begin LCM for management of reboots
LCMConfig
Set-DscLocalConfigurationManager -Path .\LCMConfig

# Compile and apply InstallOctopus configuration
InstallOctopus -ComputerName $instanceName
Start-DscConfiguration -Path .\InstallOctopus\ -Verbose -Wait -Force

InstallScaleFT
Start-DscConfiguration -Path .\InstallScaleFT\ -Verbose -Wait -Force

# Enable rebooting if needed
$global:DSCMachineStatus = 1
# Rename the computer 
ScriptRenameComputer -NewComputerName $instanceName
Start-DscConfiguration -Path .\ScriptRenameComputer\ -Verbose -Wait -Force
</powershell>
