#$clover_database_url  = ""
#$clover_database_user = ""
#$clover_database_pass = ""
#$clover_database_db   = ""

Write-Output "Apache Zip File: ${apache_zip_file}"
Write-Output "Clover Zip File: ${clover_zip_file}"
$apacheZip              = ${apache_zip_file}
$cloverTomcatZip        = ${clover_zip_file}
$clover_assets        = "C:\clover_assets"
# $srcBucketName        = "filevine-devops"
# $cloverTomcatZip      = "CloverDXServer.5.7.0.Tomcat-9.0.22.zip"
# $apacheZip            = "apache-tomcat-win.x64.zip"
$tomcatDir            = "C:\tomcat"

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

if (Test-Path $tomcatDir) {
    Write-Output "File Path ${tomcatDir} Exists"
} else {
    Write-Output "File Path ${tomcatDir} Does not Exists"
    New-Item $tomcatDir -ItemType directory

    # Let's create a new directory to store all of our fun scripts and stuff
    Write-Output "Creating Tomcat Directory: $tomcatDir"
}

Push-Location $clover_assets 

# unzip $clover_assets\CloverDXServer.5.5.1.Tomcat-9.0.22.zip $tomcatDir
unzip $clover_assets\$cloverTomcatZip $tomcatDir


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
Unzip "$clover_assets\$apacheZip" "C:\tomcat\v9" 
#apache-tomcat-win.x64.zip" "c:\tomcat\v9\"
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

# $clover_assets = "C:\clover_assets"
$start_time = Get-Date
Unzip "$clover_assets\ROOT.zip" "$tomcatDirectory\webapps\"
Push-Location $tomcatDirectory\webapps

# We want to copy the clover.war to the current directory
New-Item $tomcatDirectory\webapps\clover -ItemType directory
Copy-Item -Path $clover_assets\clover.war -Destination $tomcatDirectory\webapps\clover\clover.war
New-Item $tomcatDirectory\webapps\profiler -ItemType directory
Copy-Item -Path $clover_assets\profiler.war -Destination $tomcatDirectory\webapps\profiler\profiler.war
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
Unzip "$clover_assets\secure-cfg-tool.5.6.0.zip" "$clover_assets\secure-cfg\"
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
try {
    Set-Service $serviceName -StartupType Disabled
    Stop-Service -Name $serviceName
} catch {
    Write-Output "An Error Occurred"  -ForegroundColor RED
    Write-Output $Error[0].Exception | Get-Member
} finally {
    $Error.Clear()
}
Write-Output "Stop IIS - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

# start up Tomcat
$start_time = Get-Date
Copy-Item -Path $clover_assets\clover-setup.bat -Destination $tomcatDirectory\bin\clover-setup.bat
Write-Output "Copy clover-setup.bat"

Push-Location $tomcatDirectory\bin
.\clover-setup.bat
Write-Output "Install Tomcat Service - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "execute clover-setup.bat"

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
