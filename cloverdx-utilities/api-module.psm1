#order of operations
# userGroups, users, sandboxes, 

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