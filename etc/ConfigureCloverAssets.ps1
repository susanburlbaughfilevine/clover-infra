$config = Import-PowershellDataFile $env:SYSTEMDRIVE\clover-assets\clover-assets-manifest.psd1

# Stop any running Java and Tomcat processes. This must be done, or the jdk directory cannot be replaced on a running Clover instance
# Attempt to perform this a maximum of 5 times, waiting 1 second after each

(Get-Process | Where-Object {($_.name -like "*java*") -or ($_.name -like "*tomcat*")}).ForEach({$_ | Stop-Process -Verbose -Force})
(Get-Service | Where-Object {$_.Name -like "Tomcat9"}).ForEach({Stop-Service -Name "Tomcat9" -Verbose -Force})

Invoke-Expression 'cmd.exe /c "sc delete Tomcat9"'

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

# SecureCfgTool install
New-Item -Type Directory -Path $tomcatPath\webapps\clover\
Set-Location $env:SYSTEMDRIVE\clover-assets\
Expand-Archive "$($env:SYSTEMDRIVE)\clover-assets\$($config["securecfg"].PackageName)" -Force
Copy-Item -Path "$($env:SYSTEMDRIVE)\clover-assets\$($config["securecfg"].PackageName.Replace('.zip',''))\secure-cfg-tool\lib\" -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\" -Recurse

# Encrypt RDS password
Set-Location "$($env:SYSTEMDRIVE)\clover-assets\$($config["securecfg"].PackageName.Replace('.zip',''))\secure-cfg-tool\"
$c = "cmd.exe /c encrypt.bat -a PBEWITHSHA256AND256BITAES-CBC-BC -c org.bouncycastle.jce.provider.BouncyCastleProvider -l $($env:SYSTEMDRIVE)\clover-assets\$($config["bouncycastle"].PackageName) --batch $($env:RDS_INSTANCE_PASSWORD)"
$encryptedPass = Invoke-Expression $c

$serverProperties = (Get-Content -Path $env:SYSTEMDRIVE\clover-assets\config\cloverServer.properties)
$serverProperties = $serverProperties.Replace("##cryptoProviderLocation##","$($tomcatPath)\webapps\clover\WEB-INF\lib\")
$serverProperties = $serverProperties.Replace("##rdsInstanceAddress##",$env:RDS_INSTANCE_ADDRESS)
$serverProperties = $serverProperties.Replace("##rdsDbPassword##", $encryptedPass)
$serverProperties = $serverProperties.Replace("##sandboxbase##", "$($env:SYSTEMDRIVE)/")
$serverProperties | Out-File -FilePath "$tomcatPath\conf\cloverServer.properties" -Encoding utf8

Copy-Item -Path $env:SYSTEMDRIVE\clover-assets\config\clover-server.xml -Destination "$tomcatPath\conf\server.xml"
$setEnvScript = (Get-Content -Path $env:SYSTEMDRIVE\clover-assets\config\setenv.bat).Replace("##tomcatConfDir##","$tomcatPath\conf\cloverServer.properties")
$setEnvScript | Out-File -FilePath "$tomcatPath\bin\setenv.bat" -Encoding utf8

# CloverDX Server and Profiler Server Installation
Set-Location $tomcatPath\webapps\clover\
& "$($env:JAVA_HOME)\bin\jar.exe" -xvf $env:SYSTEMDRIVE\clover-assets\clover.war

New-Item -Type Directory -Path $tomcatPath\webapps\profiler
Set-Location $tomcatPath\webapps\profiler\
& "$($env:JAVA_HOME)\bin\jar.exe" -xvf $env:SYSTEMDRIVE\clover-assets\profiler.war

# BouncyCastle Install
Copy-Item -Path "$($env:SYSTEMDRIVE)\clover-assets\$($config["bouncycastle"].PackageName)" -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\"

# Filevine Branding
Copy-Item -Path $env:SYSTEMDRIVE\clover-assets\FVBranding5.6.0.zip -Destination $tomcatDirectory

# PostgreSql JDBC driver installation
Copy-Item -Path $env:SYSTEMDRIVE\clover-assets\$($config["pg_jdbc"].PackageName) -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\"

# Properties files must be writable by CloverDX
Import-Module "$($env:SYSTEMDRIVE)\clover-assets\Set-UserWritablePermissions.ps1"
Set-UserWritablePermissions -filepath "$tomcatPath\conf\cloverServer.properties"

# Create HTTP redirect to /clover. Not doing this
Remove-Item -Path "$tomcatPath\webapps\ROOT\" -Recurse -Force
New-Item -Type Directory -Path "$($tomcatPath)\webapps\ROOT"
New-Item -Type File -Path "$($tomcatPath)\webapps\ROOT\index.jsp"
Set-Content -Value '<% response.sendRedirect("/clover"); %>' -Path "$($tomcatPath)\webapps\ROOT\index.jsp"

# Apache Tomcat service install
$serviceInstallScript = (Get-Content -Path $env:SYSTEMDRIVE\clover-assets\config\cloversetup.bat).Replace("##tomcatConfDir##","$($tomcatPath)\conf\cloverServer.properties")
$serviceInstallScript | Out-File -FilePath "$tomcatPath\bin\cloversetup.bat" -Encoding default
Start-Process -FilePath "$tomcatPath\bin\cloversetup.bat" -WorkingDirectory $tomcatPath\bin\ -Wait
$tomcatService = Get-Service "tomcat9"
$tomcatService | Start-Service -Verbose
$tomcatService | Set-Service -StartupType Automatic

# Create firewall rule for inbound web traffic
New-NetFirewallRule -DisplayName clover-web -Protocol tcp -Name clover-web -Enabled True -Direction Inbound -Action Allow -LocalPort 80