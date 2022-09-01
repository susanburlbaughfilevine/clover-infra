function Install-CloverDxServer
{
    [cmdletbinding()]
    Param
    (
        [string]$packageDir,
        [string]$DbInstanceAddress,
        [string]$DbInstancePassword
    )

    $config = Import-PowershellDataFile $packageDir\clover-assets-manifest.psd1

    # Stop any running Java and Tomcat processes. This must be done, or the jdk directory cannot be replaced on a running Clover instance

    $stopping = $true
    $retryMax = 10
    $currentRetries = 0

    while ($stopping)
    {
        try
        {
            if ($currentRetries -ge $retryMax)
            {
                $stopping = $false
                throw "Failed to stop java and tomcat processes within specified retry count"
            }

            (Get-Process | Where-Object {($_.name -like "*java*") -or ($_.name -like "*tomcat*") -or ($_.Name -like "*typeperf")}).ForEach({$_ | Stop-Process -Verbose -Force})
            (Get-Service | Where-Object {($_.Name -eq "Tomcat9") -and ($_.Status -eq "Running")}).ForEach({Stop-Service -Name "Tomcat9" -Force -Verbose -ErrorAction Stop})

            if ((Get-Service -Name "Tomcat9").Status -eq "Stopped")
            {
                $stopping = $false
            }
            else
            {
                throw "Failed to stop Tomcat service."
            }
        }
        catch
        {
            Write-Output "Retrying..."
            $currentRetries++
            Start-Sleep 2
        }
    }

    Invoke-Expression 'cmd.exe /c "sc delete Tomcat9"'

    Write-Host "Waiting 5 seconds for any open file handles to actually die..."
    Start-Sleep 5

    # Delete old JDK and Tomcat directories. If we need to revert due to an issue, deploy an older release
    if (Test-Path "$($env:SYSTEMDRIVE)\jdk") {Remove-Item $env:SYSTEMDRIVE\jdk -Recurse -Force}
    if (Test-Path "$($env:SYSTEMDRIVE)\tomcat") {Remove-Item $env:SYSTEMDRIVE\tomcat -Recurse -Force}

    # Extract/Install JDK and Apache Tomcat
    $tomcatDirectory = New-Item -Type Directory -Path $env:SYSTEMDRIVE\tomcat
    $jdkDirectory = New-Item -Type Directory -Path $env:SYSTEMDRIVE\jdk
    $jdkPath = Join-Path -Path $jdkDirectory.FullName -ChildPath ($config["jdk"].PackageName).Replace(".zip","")
    $tomcatPath = Join-Path -Path $tomcatDirectory.FullName -ChildPath $config["tomcat"].PackageName.Replace(".zip","")
    Expand-Archive $packageDir\$($config["tomcat"].PackageName) -Destination $tomcatDirectory.FullName
    Expand-Archive $packageDir\$($config["jdk"].PackageName) -Destination $jdkDirectory.FullName

    # Configure Tomcat installation
    [Environment]::SetEnvironmentVariable("JAVA_HOME", "$jdkPath", "Machine")
    [Environment]::SetEnvironmentVariable("JRE_HOME", "$jdkPath\bin", "Machine")
    $env:JAVA_HOME = [System.Environment]::GetEnvironmentVariable("JAVA_HOME","Machine")
    $env:JRE_HOME = [System.Environment]::GetEnvironmentVariable("JRE_HOME","Machine")

    # SecureCfgTool install
    New-Item -Type Directory -Path $tomcatPath\webapps\clover\
    Set-Location $packageDir\
    Expand-Archive "$($packageDir)\$($config["securecfg"].PackageName)" -Force
    Copy-Item -Path "$($packageDir)\$($config["securecfg"].PackageName.Replace('.zip',''))\secure-cfg-tool\lib\" -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\" -Recurse

    # Encrypt RDS password
    Set-Location "$($packageDir)\$($config["securecfg"].PackageName.Replace('.zip',''))\secure-cfg-tool\"
    $c = "cmd.exe /c encrypt.bat -a PBEWITHSHA256AND256BITAES-CBC-BC -c org.bouncycastle.jce.provider.BouncyCastleProvider -l $($packageDir)\$($config["bouncycastle"].PackageName) --batch $($DbInstancePassword)"
    #Write-Host "Executing: $c"
    $encryptedPass = Invoke-Expression $c
    #Write-Host "Result $encryptedPass"
    New-Item -Type Directory -Path $tomcatPath\conf
    $serverProperties = (Get-Content -Path $packageDir\config\cloverServer.properties)
    $serverProperties = $serverProperties.Replace("##cryptoProviderLocation##","$($tomcatPath)\webapps\clover\WEB-INF\lib\")
    $serverProperties = $serverProperties.Replace("##rdsInstanceAddress##",$DbInstanceAddress)
    $serverProperties = $serverProperties.Replace("##rdsDbPassword##", $encryptedPass)
    $serverProperties = $serverProperties.Replace("##sandboxbase##", "$($env:SYSTEMDRIVE)/")
    $serverProperties | Out-File -FilePath "$tomcatPath\conf\cloverServer.properties" -Encoding utf8

    Copy-Item -Path $packageDir\config\clover-server.xml -Destination "$tomcatPath\conf\server.xml"
    $setEnvScript = (Get-Content -Path $packageDir\config\setenv.bat).Replace("##tomcatConfDir##","$tomcatPath\conf\cloverServer.properties")
    $setEnvScript | Out-File -FilePath "$tomcatPath\bin\setenv.bat" -Encoding utf8

    # CloverDX Server and Profiler Server Installation
    Set-Location $tomcatPath\webapps\clover\
    & "$($env:JAVA_HOME)\bin\jar.exe" -xvf $packageDir\clover.war

    New-Item -Type Directory -Path $tomcatPath\webapps\profiler
    Set-Location $tomcatPath\webapps\profiler\
    & "$($env:JAVA_HOME)\bin\jar.exe" -xvf $packageDir\profiler.war

    # Install Reload4j bin, remove log4j
    New-Item -Type Directory -Path .\log4j
    Copy-Item -Path $packageDir\$($config["reload4j"].PackageName) -Destination ".\WEB-INF\lib\" -Verbose
    Remove-Item -Path ".\WEB-INF\lib\log4j-1.2.17.jar" -Verbose

    # BouncyCastle Install
    Copy-Item -Path "$($packageDir)\$($config["bouncycastle"].PackageName)" -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\"

    # Filevine Branding
    Copy-Item -Path $packageDir\FVBranding5.6.0.zip -Destination $tomcatDirectory

    # PostgreSql JDBC driver installation
    Copy-Item -Path $packageDir\$($config["pg_jdbc"].PackageName) -Destination "$($tomcatPath)\webapps\clover\WEB-INF\lib\"

    # Properties files must be writable by CloverDX
    Import-Module "$($packageDir)\Set-UserWritablePermissions.ps1"
    Set-UserWritablePermissions -filepath "$tomcatPath\conf\cloverServer.properties"

    # Create HTTP redirect to /clover. Not doing this
    Remove-Item -Path "$tomcatPath\webapps\ROOT\" -Recurse -Force
    New-Item -Type Directory -Path "$($tomcatPath)\webapps\ROOT"
    New-Item -Type File -Path "$($tomcatPath)\webapps\ROOT\index.jsp"
    Set-Content -Value '<% response.sendRedirect("/clover"); %>' -Path "$($tomcatPath)\webapps\ROOT\index.jsp"

    # Apache Tomcat service install
    $serviceInstallScript = (Get-Content -Path $packageDir\config\cloversetup.bat).Replace("##tomcatConfDir##","$($tomcatPath)\conf\cloverServer.properties")
    $serviceInstallScript | Out-File -FilePath "$tomcatPath\bin\cloversetup.bat" -Encoding default
    Start-Process -FilePath "$tomcatPath\bin\cloversetup.bat" -WorkingDirectory $tomcatPath\bin\ -Wait
    $tomcatService = Get-Service "tomcat9"
    $tomcatService | Start-Service -Verbose
    $tomcatService | Set-Service -StartupType Automatic

    # Create firewall rule for inbound web traffic
    if ( -not (@(Get-NetFirewallRule -Name clover-web -ErrorAction SilentlyContinue).count -eq 1)) {
        New-NetFirewallRule -DisplayName clover-web -Protocol tcp -Name clover-web -Enabled True -Direction Inbound -Action Allow -LocalPort 80
    }

    # Cloudwatch Agent Configuration
    $cloudwatchConfig = (Get-Content -Path $packageDir\config\cloudwatch.json).Replace("##tomcatDir##","$($tomcatPath.Replace("\","\\"))")
    $cloudwatchConfig | Out-File -FilePath "$($env:SYSTEMDRIVE)\ProgramData\Amazon\AmazonCloudWatchAgent\Configs\ApplicationDefault.json" -Encoding default -Force

}