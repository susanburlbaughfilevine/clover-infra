# This script is run automatcially by Octopus Deploy
# https://octopus.com/docs/deployments/custom-scripts/scripts-in-packages

$packagePath = $OctopusParameters['Octopus.Action.Package.InstallationDirectoryPath']

Set-Location $packagePath

Import-Module ./Install-CloverDxServer.psm1

Install-CloverDxServer -packageDir $packagePath -DbInstancePassword $rds_user_password -DbInstanceAddress $db_instance_address

Import-Module "$($packagePath)\cloverdx-utilities\api-module.psm1"

$tenantName = $OctopusParameters['Octopus.Deployment.Tenant.Name']

if (_isFirstDeploy)
{
    Write-Output "We've determined that this is the first deploy for $($tenantName)"
    Write-Output "Performing initial user configuration"
    Write-Output "Here is the clover_admin_password $($clover_admin_password)"

    # Post deploy, this username/password combination will no longer be valid. 
    $credential = New-BasicCredential -UserName "clover" -Password "clover"
    $config = Import-PowershellDataFile "$($packagePath)\clover-assets-manifest.psd1"

    foreach ($configType in @("userGroups","users"))
    {
        $resultantXml = ""

        if ($configType -eq "users")
        {
            $encryptParams = @{
                "EncryptionProviderDirectory" = $packagePath;
                "PlainText"                   = $clover_admin_password;
                "SecureCfgDirectory"          = "$($packagePath)\$($config["securecfg"].PackageName.Replace('.zip',''))\secure-cfg-tool\"
            }

            #$encryptedPassword = Encrypt-CloverDxValue @encryptParams

            $configFullPath = "$($packagePath)/config/CloverDX/$configType/$($tenantName).$($configType).xml"
            [xml]$baseXml = Get-Content $configFullPath -Raw
            $xmlTextReader = [System.Xml.XmlTextReader]::new($configFullPath)
            $xmlNsMgr = [System.Xml.XmlNamespaceManager]::new($xmlTextReader.NameTable)
            $xmlNsMgr.AddNamespace("cs", "http://cloveretl.com/server/data")
            $cloverUserNode = $baseXml.SelectSingleNode('//cs:password[preceding-sibling::cs:username[text()="clover"]]', $xmlNsMgr)
            $cloverUserNode.'#text' = $clover_admin_password
            $baseXml.Save($configFullPath)

            $resultantXml = Get-Content $configFullPath -Raw

            Write-Output "Here is the XML"
            $resultantXml
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

$credential = New-BasicCredential -UserName "clover" -Password $clover_admin_password

foreach ($configType in @("userGroups","sandboxes","jobConfigs","schedules","eventListeners","dataServices","tempSpaces","operationsDashboards"))
{
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