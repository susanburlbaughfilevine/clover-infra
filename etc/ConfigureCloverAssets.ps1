$config = Import-PowershellDataFile $env:SYSTEMDRIVE\clover-assets\clover-assets-manifest.psd1

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
[Environment]::SetEnvironmentVariable("JAVA_HOME", "$jdkPath\bin", "Machine")
[Environment]::SetEnvironmentVariable("JRE_HOME", "$jdkPath", "Machine")
$env:JAVA_HOME = [System.Environment]::GetEnvironmentVariable("JAVA_HOME","Machine")
$env:JRE_HOME = [System.Environment]::GetEnvironmentVariable("JRE_HOME","Machine")
Copy-Item -Path $env:SYSTEMDRIVE\clover-assets\cloverServer.properties -Destination "$tomcatPath\conf\"
$setEnvScript = (Get-Content -Path $env:SYSTEMDRIVE\clover-assets\setenv.bat).Replace("##tomcatConfDir##","$tomcatPath\conf\cloverServer.properties")
New-Item -Type File -Path "$tomcatPath\bin\setenv.bat" -Value $setEnvScript

#Start-Process -FilePath $tomcatPath\bin\startup.bat -Wait