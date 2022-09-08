<#
    .SYNOPSIS
    Waits for the CloverDX_META database to be restored onto the worker node. 

    .DESCRIPTION
    This script is intended to execute before CloverDX_META DbUp runs in the pipeline to ensure that if a valid backup exists, that it is restored 
    prior to DbUp running and creating an empty database.

    CloverDX_META is restored via the Worker Node's DSC configuration. Execution of the Worker Node's DSC configuration will* result in a reboot prior
    to the DSC configuration being fully applied, causing the Octopus deployment task to return succesfully before it has run to completion. As such, we 
    need a method such as this one to determine when the system will be ready for DbUp to run against it.

    If the S3 bucket that is expected to be holding the CloverDX_META backups does not exist in the environment, this script will return immediatley and allow
    the CloverDX_META DbUp to run.

    This script is intended to run on the Worker Node
#>

param (
    [string]$EnvironmentName
)

function Get-DbCredentials {

    $filter = [Amazon.SecretsManager.Model.Filter]@{
        "Key"    = "Name"
        "Values" = "cloveretl-ssh-credentials"
    }

    $secSecret = Get-SECSecretList -Filter $filter | Select-Object -First 1

    if ($null -eq $secSecret) {
        return $false
    }
    
    $password = ((Get-SECSecretValue -SecretId $secSecret.name).SecretString | ConvertFrom-Json).password | ConvertTo-SecureString -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential "clover_etl_login", $password
}

Import-Module AWSPowershell

$bucketName = "$($($EnvironmentName).ToLower())-cloverdx-meta-backups"
$bucketExists = $(Get-S3Bucket).BucketName.Contains($bucketName)

if (-not $bucketExists) {
    Write-Host "Bucket $bucketName does not exist."
    return
}

if (-not (Get-S3Object -BucketName $bucketName).Count -gt 0) {
    Write-Host "Bucket $bucketName has no objects to be restored"
    return
}

$stopTime = ([datetime]::now).AddMinutes(35)
$dbNotRestored = $true

while ($dbNotRestored) {

    $testParams = @{
        Credential = Get-DbCredentials
        ServerInstance = "localhost"
        Query = "SELECT * FROM sys.databases"
    }

    try
    {
        $dbExists = (Invoke-Sqlcmd @testParams).Name.Contains("CloverDX_META")
    }
    catch
    {
        Write-Host "There was an error communicating with the database"
        Write-Host $_.ErrorDetails
        Write-Host $_.Exception
        Write-Host $_.ScriptStackTrace
    }

    if ($dbExists) {
        $dbNotRestored = $false
        break
    }

    if ([datetime]::now -gt $stopTime) {
        throw "Timeout reached! CloverDX_META database not restored!"
    }
}




