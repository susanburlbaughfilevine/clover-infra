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
Copy-Item -Path $env:SYSTEMDRIVE\clover-assets\config\cloverServer.properties -Destination "$tomcatPath\conf\"
Copy-Item -Path $env:SYSTEMDRIVE\clover-assets\config\clover-server.xml -Destination "$tomcatPath\conf\server.xml"
$setEnvScript = (Get-Content -Path $env:SYSTEMDRIVE\clover-assets\config\setenv.bat).Replace("##tomcatConfDir##","$tomcatPath\conf\cloverServer.properties")
New-Item -Type File -Path "$tomcatPath\bin\setenv.bat" -Value $setEnvScript

# CloverDX Server and Profiler Server Installation
New-Item -Type Directory -Path $tomcatPath\webapps\clover\
Set-Location $tomcatPath\webapps\clover\
& "$($env:JAVA_HOME)\jar.exe" -xvf $env:SYSTEMDRIVE\clover-assets\clover.war

New-Item -Type Directory -Path $tomcatPath\webapps\profiler
Set-Location $tomcatPath\webapps\profiler\
& "$($env:JAVA_HOME)\jar.exe" -xvf $env:SYSTEMDRIVE\clover-assets\profiler.war

# BouncyCastle Install
Copy-Item -Path "$($env:SYSTEMDRIVE)\clover-assets\$($config["bouncycastle"].PackageName)" -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\"

#SecureCfgTool install
Set-Location $env:SYSTEMDRIVE\clover-assets\
Expand-Archive "$($env:SYSTEMDRIVE)\clover-assets\$($config["securecfg"].PackageName)"
Copy-Item -Path "$($env:SYSTEMDRIVE)\clover-assets\$($config["securecfg"].PackageName.Replace('.zip',''))\lib\" -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\" -Recurse

Write-Output "Starting Apache Tomcat"
Start-Process -FilePath $tomcatPath\bin\startup.bat -WorkingDirectory $tomcatPath\bin\ -PassThru