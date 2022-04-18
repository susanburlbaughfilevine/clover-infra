# This script is run automatcially by Octopus Deploy
# https://octopus.com/docs/deployments/custom-scripts/scripts-in-packages


Import-Module clover-powershell
Import-Module ./Install-CloverDxServer.psm1

$packagePath = $OctopusParameters['Octopus.Action.Package.InstallationDirectoryPath']

Set-Location $packagePath

Install-CloverDxServer -packageDir $packagePath -DbInstancePassword $rds_user_password -DbInstanceAddress $db_instance_address

$tenantName = $OctopusParameters['Octopus.Deployment.Tenant.Name']

if (!$initial_deploy_complete)
{
    Write-Output "We've determined that this is the first deploy for $($tenantName)"
    Write-Output "Performing initial user configuration"

    # Post deploy, this username/password combination will no longer be valid. 
    $credential = New-BasicCredential -UserName "clover" -Password "clover"
    $config = Import-PowershellDataFile "$($packagePath)\clover-assets-manifest.psd1"

    foreach ($configType in @("userGroups","users"))
    {
        $resultantXml = ""

        if ($configType -eq "users")
        {
            $configFullPath = "$($packagePath)/config/CloverDX/$configType/$($tenantName).$($configType).xml"
            [xml]$baseXml = Get-Content $configFullPath -Raw
            $xmlTextReader = [System.Xml.XmlTextReader]::new($configFullPath)
            $xmlNsMgr = [System.Xml.XmlNamespaceManager]::new($xmlTextReader.NameTable)
            $xmlNsMgr.AddNamespace("cs", "http://cloveretl.com/server/data")
            $cloverUserNode = $baseXml.SelectSingleNode('//cs:password[preceding-sibling::cs:username[text()="clover"]]', $xmlNsMgr)
            $cloverUserNode.'#text' = $clover_admin_password
            $baseXml.Save($configFullPath)

            $resultantXml = Get-Content $configFullPath -Raw
        }

        if ($configType -eq "userGroups")
        {
            $configFullPath = "$($packagePath)/config/CloverDX/$configType/$($tenantName).$($configType).xml"
            $resultantXml = Get-Content $configFullPath -Raw
        }

        $params = @{
            "dryRun"         = $false;
            "include"        = $configType;
            "configuration"  = $resultantXml;
            "credential"     = $credential;
            "BaseUrl"        = "http://localhost"
        }

        Set-ServerConfiguration @params
    }
}

$credential = New-BasicCredential -UserName "clover" -Password $cloverdx_admin_password

foreach ($configType in @("userGroups","sandboxes","jobConfigs","schedules","eventListeners","operationsDashboards","dataServices","tempSpaces"))
{
    if (Test-Path "$($packagePath)/config/CloverDX/$configType/all.$($configType.ToLower()).xml") {
        Write-Host "Applying base configuration"

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

    try
    {
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
