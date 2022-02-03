# This script is run automatcially by Octopus Deploy
# https://octopus.com/docs/deployments/custom-scripts/scripts-in-packages

$env:RDS_INSTANCE_ADDRESS=$db_instance_address

$env:RDS_INSTANCE_PASSWORD=$rds_user_password

Set-Location $OctopusParameters['Octopus.Action.Package.InstallationDirectoryPath']

& ./ConfigureCloverAssets.ps1 $OctopusParameters['Octopus.Action.Package.InstallationDirectoryPath']


if ($isFirstDeploy)
{
    Write-Output "We've determined that this is the first deploy for $($OctopusParameters['Octopus.Environment.TenantName'])"
    Write-Output "Performing initial user configuration"

    Import-Module .\cloverdx-utilities\clover-dx-api.psm1

    # Post deploy, this username/password combination will no longer be valid. 
    $credential = New-BasicCredential -UserName "clover" -Password "clover"

    foreach ($configType in @("users"))
    {
        $config = Get-Content "./config/CloverDX/$include/$($OctopusParameters['Octopus.Environment.TenantName']).$($include).xml" -Raw

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
        $config = Get-Content "./config/CloverDX/$include/$($OctopusParameters['Octopus.Environment.TenantName']).$($include.ToLower()).xml" -Raw
    }
    catch [System.Management.Automation.ItemNotFoundException]
    {
        Write-Host "A $($configType) configuration at /config/CloverDX/$include/$($OctopusParameters['Octopus.Environment.TenantName']).$($include).xml was not found."
        Write-Host "Please place a $($configType) configuration in the directory shown above and try again."
    }
    catch
    {
        Write-Host "Failed to read configuration at ./config/CloverDX/$include/$($OctopusParameters['Octopus.Environment.TenantName']).$($include).xml"
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



