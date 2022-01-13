$config = Import-PowershellDataFile $env:SYSTEMDRIVE\clover-assets\clover-assets-manifest.psd1

# Stop any running Java and Tomcat processes. This must be done, or the jdk directory cannot be replaced on a running Clover instance
(Get-Service | Where-Object {$_.Name -like "Tomcat9"}).ForEach({Stop-Service -Name "Tomcat9" -Verbose -Force})
$processes = Get-Process | Where-Object {($_.name -like "*java*") -or ($_.name -like "*tomcat*")}
$processes.ForEach({$_ | Stop-Process -Verbose -Force})

# Delete old JDK and Tomcat directories. If we need to revert due to an issue, deploy an older release
if (Test-Path "$($env:SYSTEMDRIVE)\jdk") {Remove-Item $env:SYSTEMDRIVE\jdk -Recurse -Force}
if (Test-Path "$($env:SYSTEMDRIVE)\tomcat") {Remove-Item $env:SYSTEMDRIVE\tomcat -Recurse -Force}

# Extract/Install JDK and Apache Tomcat
$tomcatDirectory = New-Item -Type Directory -Path $env:SYSTEMDRIVE\tomcat
$jdkDirectory = New-Item -Type Directory -Path $env:SYSTEMDRIVE\jdk
$jdkPath = Join-Path -Path $jdkDirectory.FullName -ChildPath ($config["jdk"].PackageName).Replace(".zip","")
$tomcatPath = Join-Path -Path $tomcatDirectory.FullName -ChildPath $config["tomcat"].PackageName.Replace(".zip","")
Expand-Archive $env:SYSTEMDRIVE\clover-assets\$($config["tomcat"].PackageName) -Destination $tomcatDirectory.FullName
Expand-Archive $env:SYSTEMDRIVE\clover-assets\$($config["jdk"].PackageName) -Destination $jdkDirectory.FullName

# Configure Tomcat installation
[Environment]::SetEnvironmentVariable("JAVA_HOME", "$jdkPath", "Machine")
[Environment]::SetEnvironmentVariable("JRE_HOME", "$jdkPath\bin", "Machine")
$env:JAVA_HOME = [System.Environment]::GetEnvironmentVariable("JAVA_HOME","Machine")
$env:JRE_HOME = [System.Environment]::GetEnvironmentVariable("JRE_HOME","Machine")

$serverProperties = (Get-Content -Path $env:SYSTEMDRIVE\clover-assets\config\cloverServer.properties)
$serverProperties = $serverProperties.Replace("##cryptoProviderLocation##","$($tomcatPath)\webapps\clover\WEB-INF\lib\")
$serverProperties = $serverProperties.Replace("##rdsInstanceAddress##",$env:RDS_INSTANCE_ADDRESS)
$serverProperties = $serverProperties.Replace("##rdsDbPassword##",$env:RDS_INSTANCE_PASSWORD)
$serverProperties | Out-File -FilePath "$tomcatPath\conf\cloverServer.properties"

Copy-Item -Path $env:SYSTEMDRIVE\clover-assets\config\clover-server.xml -Destination "$tomcatPath\conf\server.xml"
$setEnvScript = (Get-Content -Path $env:SYSTEMDRIVE\clover-assets\config\setenv.bat).Replace("##tomcatConfDir##","$tomcatPath\conf\cloverServer.properties")
$setEnvScript | Out-File -FilePath "$tomcatPath\bin\setenv.bat"

# CloverDX Server and Profiler Server Installation
New-Item -Type Directory -Path $tomcatPath\webapps\clover\
Set-Location $tomcatPath\webapps\clover\
& "$($env:JAVA_HOME)\bin\jar.exe" -xvf $env:SYSTEMDRIVE\clover-assets\clover.war

New-Item -Type Directory -Path $tomcatPath\webapps\profiler
Set-Location $tomcatPath\webapps\profiler\
& "$($env:JAVA_HOME)\bin\jar.exe" -xvf $env:SYSTEMDRIVE\clover-assets\profiler.war

# BouncyCastle Install
Copy-Item -Path "$($env:SYSTEMDRIVE)\clover-assets\$($config["bouncycastle"].PackageName)" -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\"

# SecureCfgTool install
Set-Location $env:SYSTEMDRIVE\clover-assets\
Expand-Archive "$($env:SYSTEMDRIVE)\clover-assets\$($config["securecfg"].PackageName)"
Copy-Item -Path "$($env:SYSTEMDRIVE)\clover-assets\$($config["securecfg"].PackageName.Replace('.zip',''))\secure-cfg-tool\lib\" -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\" -Recurse

# PostgreSql JDBC driver installation
Copy-Item -Path $env:SYSTEMDRIVE\clover-assets\$($config["pg_jdbc"].PackageName) -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\"

# Apache Tomcat service install
$serviceInstallScript = (Get-Content -Path $env:SYSTEMDRIVE\clover-assets\config\cloversetup.bat).Replace("##tomcatConfDir##","$($tomcatPath)\conf\cloverServer.properties")
$serviceInstallScript | Out-File -FilePath "$tomcatPath\bin\cloversetup.bat"
Start-Process -FilePath "$tomcatPath\bin\cloversetup.bat" -WorkingDirectory $tomcatPath\bin\ -Wait
$tomcatService = Get-Service "tomcat9"
$tomcatService | Start-Service -Verbose
$tomcatService | Set-Service -StartupType Automatic