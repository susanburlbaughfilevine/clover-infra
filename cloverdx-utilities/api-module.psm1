#order of operations
# userGroups, users, sandboxes, 

function Encrypt-CloverDxValue
{
    [cmdletbinding()]
    Param
    (
        [string]$PlainText,
        [string]$SecureCfgDirectory,
        [string]$EncryptionProviderDirectory
    )

    Write-Output "Encrypting value using org.bouncycastle.jce.provider.BouncyCastleProvider"

    Set-Location $SecureCfgDirectory
    $c = "cmd.exe /c encrypt.bat -a PBEWITHSHA256AND256BITAES-CBC-BC -c org.bouncycastle.jce.provider.BouncyCastleProvider -l $($EncryptionProviderDirectory)\$($config["bouncycastle"].PackageName) --batch $($clover_admin_password)"
    $encryptedPass = Invoke-Expression $c
    return $encryptedPass
}



function _isFirstDeploy()
{
    # initial_deploy_complete variable should be defined in octopus
    return (!$initial_deploy_complete)
}
function New-BasicCredential
{
    [cmdletbinding()]
    [OutputType([PSCredential])]
    Param
    (
        [string]$UserName,
        [string]$Password
    )

    $secStringPassword = ConvertTo-SecureString $Password -AsPlainText -Force

    return (
        New-Object System.Management.Automation.PSCredential ($UserName, $secStringPassword)
    )
}

function Get-ServerConfiguration
{
    [cmdletbinding()]
    Param
    (
        [ValidateSet("all","users","userGroups","sandboxes","jobConfigs","schedulesd","eventListeners","dataServices","tempSpaces","operationsDashboards")]
        [string[]]$include,
        [pscredential]$Credentials,
        [string]$BaseUrl
    )

    $headers = @{"X-Requested-By"="Filevine CloverDX Powershell Module"}

    $params = @{
        "Method"     = "GET";
        "Uri"        = "$($BaseUrl)/clover/api/rest/v1/server/configuration/export?include=$($include)";
        "Headers"    = $headers;
        "Credential" = $Credentials
    }
    
    return (
        Invoke-RestMethod @params
    )
}

# $config = get-content .\config\CloverDX\sandboxes\dm-dev.sandboxes.xml -Raw
function Set-ServerConfiguration
{
    [cmdletbinding()]
    Param
    (
        [bool]$dryRun = $true,
        [bool]$newOnly = $false,
        [bool]$override = $false,
        [ValidateSet("all","users","userGroups","sandboxes","jobConfigs","schedules","eventListeners","dataServices","tempSpaces","operationsDashboards")]
        [string[]]$include,
        [string]$Configuration,
        [pscredential]$Credentials,
        [string]$BaseUrl
    )

    $headers = @{"X-Requested-By"="Filevine CloverDX Powershell Module"}

    $params = @{
        "Method"       = "POST";
        "Uri"          = "$($BaseUrl)/clover/api/rest/v1/server/configuration/import?dryRun=$($dryRun)&newOnly=$($newOnly)&override=$($override)&include=$($include)";
        "Headers"      = $headers;
        "Credential"   = $Credentials;
        "Body"         = $Configuration;
        "ContentType" = "application/octet-stream"
    }
    
    return (
        Invoke-RestMethod @params
    )
}