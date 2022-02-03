# This script is run automatcially by Octopus Deploy
# https://octopus.com/docs/deployments/custom-scripts/scripts-in-packages

$env:RDS_INSTANCE_ADDRESS=$db_instance_address

$env:RDS_INSTANCE_PASSWORD=$rds_user_password

$packagePath = $OctopusParameters['Octopus.Action.Package.InstallationDirectoryPath']
Set-Location $packagePath

& ./ConfigureCloverAssets.ps1 $packagePath

Import-Module "$($packagePath)\cloverdx-utilities\api-module.psm1"

if (_isFirstDeploy)
{
    Write-Output "We've determined that this is the first deploy for $($OctopusParameters['Octopus.Deployment.Tenant.Name'])"
    Write-Output "Performing initial user configuration"

    # Post deploy, this username/password combination will no longer be valid. 
    $credential = New-BasicCredential -UserName "clover" -Password "clover"

    foreach ($configType in @("users"))
    {
        $config = Get-Content "$($packagePath)/config/CloverDX/$configType/$($OctopusParameters['Octopus.Deployment.Tenant.Name']).$($configType).xml" -Raw

        $params = @{
            dryRun         = $false;
            $include       = $configType;
            $configuration = $config;
            $credential    = $credential;
            $BaseUrl       = "http://localhost"
        }

        Set-ServerConfiguration @params
    }
}

$credential = New-BasicCredential -UserName "clover" -Password $clover_admin_password

foreach ($configType in @("userGroups","sandboxes","jobConfigs","schedules","eventListeners","dataServices","tempSpaces","operationsDashboards"))
{
    try
    {
        $config = Get-Content "$($packagePath)/config/CloverDX/$configType/$($OctopusParameters['Octopus.Deployment.Tenant.Name']).$($configType.ToLower()).xml" -Raw
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        Write-Host "A $($configType) configuration at $($packagePath)/config/CloverDX/$configType/$($OctopusParameters['Octopus.Deployment.Tenant.Name']).$($configType).xml was not found."
        Write-Host "Please place a $($configType) configuration in the directory shown above and try again."
    }
    catch
    {
        Write-Host "Failed to read configuration at $($packagePath)/config/CloverDX/$configType/$($OctopusParameters['Octopus.Deployment.Tenant.Name']).$($configType).xml"
        throw $_.Exception
    }

    $params = @{
        dryRun         = $false;
        $include       = $configType;
        $configuration = $config;
        $credential    = $credential;
        $BaseUrl       = "http://localhost"
    }

    Set-ServerConfiguration @params
}



