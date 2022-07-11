# This script is run automatcially by Octopus Deploy
# https://octopus.com/docs/deployments/custom-scripts/scripts-in-packages


Import-Module clover-powershell
Import-Module ./Install-CloverDxServer.psm1

$packagePath = $OctopusParameters['Octopus.Action.Package.InstallationDirectoryPath']

Set-Location $packagePath

Write-Host "Admin password is $cloverdx_admin_password"
Write-Host "RDS Password is $rds_user_password"
Write-Host "Db Instance address is $db_instance_address"

Install-CloverDxServer -packageDir $packagePath -DbInstancePassword $rds_user_password -DbInstanceAddress $db_instance_address

$tenantName = $OctopusParameters['Octopus.Deployment.Tenant.Name']

$credential = New-BasicCredential -UserName "clover" -Password $cloverdx_admin_password



foreach ($configType in @("userGroups","users","sandboxes","jobConfigs","schedules","eventListeners","operationsDashboards","dataServices","tempSpaces"))
{
    try
    {
        Write-Host "Applying configuration for $configType"

        if ($configType -eq "users")
        {
            $configFullPath = "$($packagePath)/config/CloverDX/$configType/all.$($configType.ToLower()).xml"
            [xml]$baseXml = Get-Content $configFullPath -Raw
            $xmlTextReader = [System.Xml.XmlTextReader]::new($configFullPath)
            $xmlNsMgr = [System.Xml.XmlNamespaceManager]::new($xmlTextReader.NameTable)
            $xmlNsMgr.AddNamespace("cs", "http://cloveretl.com/server/data")
            $cloverUserNode = $baseXml.SelectSingleNode('//cs:password[preceding-sibling::cs:username[text()="clover"]]', $xmlNsMgr)
            $cloverUserNode.'#text' = $cloverdx_admin_password
            $baseXml.Save($configFullPath)

            $config = Get-Content $configFullPath -Raw

            $params = @{
                "dryRun"         = $false;
                "include"       = $configType; 
                "configuration" = $config;
                "credential"    = $credential;
                "BaseUrl"       = "http://localhost"
            }

            Set-ServerConfiguration @params

            Write-Host "Applying $tenantName configuration for $configType"
            $config = Get-Content "$($packagePath)/config/CloverDX/$configType/$($tenantName).$($configType.ToLower()).xml" -Raw
    
            $params = @{
                "dryRun"         = $false;
                "include"       = $configType;
                "configuration" = $config;
                "credential"    = $credential;
                "BaseUrl"       = "http://localhost"
            }
    
            Set-ServerConfiguration @params
        }

        # Apply the *all* configuration if it exists
        if (Test-Path "$($packagePath)/config/CloverDX/$configType/all.$($configType.ToLower()).xml") {
            Write-Host "Applying base configuration for $configType"

            $config = Get-Content "$($packagePath)/config/CloverDX/$configType/all.$($configType.ToLower()).xml" -Raw

            $params = @{
                "dryRun"         = $false;
                "include"       = $configType; 
                "configuration" = $config;
                "credential"    = $credential;
                "BaseUrl"       = "http://localhost"
            }

            Set-ServerConfiguration @params
        }


        Write-Host "Applying $tenantName configuration for $configType"
        $config = Get-Content "$($packagePath)/config/CloverDX/$configType/$($tenantName).$($configType.ToLower()).xml" -Raw

        $params = @{
            "dryRun"         = $false;
            "include"       = $configType;
            "configuration" = $config;
            "credential"    = $credential;
            "BaseUrl"       = "http://localhost"
        }

        Set-ServerConfiguration @params
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        Write-Host "A $($configType) configuration at $($packagePath)/config/CloverDX/$configType/$($tenantName).$($configType).xml was not found."
        Write-Host "Please place a $($configType) configuration in the directory shown above and try again."
    }
    catch
    {
        Write-Host "Failed to read configuration at $($packagePath)/config/CloverDX/$configType/$($tenantName).$($configType).xml"
        throw $_.Exception
    }
}
