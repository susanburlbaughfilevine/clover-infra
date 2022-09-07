function Create-BucketIfNotExists
{
    [cmdletbinding()]
    Param
    (
        [string]$EnvironmentName,
        [string]$AWSRegion
    )

#     # This function is meant to be temporary since this is a change that is being introduced 
#     # while a worker refresh is pending, meaning there will be race condition between bucket
#     # creation and needing to perform the backup. To be removed at a later date and instead,
#     # import the resultant s3 bucket into the tf state

    $bucketName = "$($($EnvironmentName).ToLower())-cloverdx-meta-backups"
    $bucketExists = $(Get-S3Bucket).BucketName.Contains($bucketName)

    if (-not $bucketExists)
    {
        $createBucketParams = @{
            "BucketName"    = $bucketName
            "CannedAclName" = [Amazon.S3.S3CannedACL]::Private
            "Region"        = $AWSRegion
        }

        $createBucketResult = New-S3Bucket @createBucketParams -Verbose
        Write-Host "Create bucket result $createBucketResult"

        $publicAccessBlockConfig = @{
            "BucketName"                                          = $BucketName
            "PublicAccessBlockConfiguration_BlockPublicAcl"       = $true
            "PublicAccessBlockConfiguration_BlockPublicPolicy"    = $true
            "PublicAccessBlockConfiguration_IgnorePublicAcl"      = $true
            "PublicAccessBlockConfiguration_RestrictPublicBucket" = $true
        }

        Add-S3PublicAccessBlock @publicAccessBlockConfig

        $kmsAlias = Get-KMSAliasList | Where-Object {$_.AliasName -like "*dm-import*"}

        $encryptionRule = [Amazon.S3.Model.ServerSideEncryptionRule]@{
            "BucketKeyEnabled" = $true
            "ServerSideEncryptionByDefault" = [Amazon.S3.Model.ServerSideEncryptionByDefault]@{
                "ServerSideEncryptionKeyManagementServiceKeyId" = $kmsAlias.TargetKeyId
                "ServerSideEncryptionAlgorithm" = [Amazon.S3.ServerSideEncryptionMethod]::AWSKMS
            }
        }

        $setEncryptParams = @{
            "ServerSideEncryptionConfiguration_ServerSideEncryptionRule" = $encryptionRule
            "BucketName" = $createBucketResult.BucketName
        }

        Set-S3BucketEncryption @setEncryptParams
    }
    
    Write-Host "Create-BucketIfNotExists finished for bucket $bucketName"
}

function Get-DbCredentials
{

    [cmdletbinding()]
    [OutputType([System.Management.Automation.PSCredential])]
    Param()
    Get-Module
    Import-Module AWSPowershell -Force -ErrorAction Continue

    $filter = [Amazon.SecretsManager.Model.Filter]@{
        "Key"    = "Name"
        "Values" = "cloveretl-ssh-credentials"
    }

    $secSecret = Get-SECSecretList -Filter $filter | Select-Object -First 1

    if ($null -eq $secSecret) {
        throw "No secret found"
    }
    
    $password = ((Get-SECSecretValue -SecretId $secSecret.name).SecretString | ConvertFrom-Json).password | ConvertTo-SecureString -AsPlainText -Force

    New-Object System.Management.Automation.PSCredential "clover_etl_login", $password
}

function Start-CloverDXMetaBackup
{
    [cmdletbinding()]
    Param
    (
        [string]$EnvironmentName,
        [string]$AWSRegion
    )
    
    Write-Host "Here is the plan output!"
	$OctopusParameters["planJson"]
    
    Write-Host "Creating backup bucket if it doesn't exist"
    Create-BucketIfNotExists -EnvironmentName $EnvironmentName -AWSRegion $AWSRegion

    # Read TF plan output from Plan step
    $backup = $false
    if ($null -ne $OctopusParameters["planJson"])
    {
        Write-Host "We've detected some changes"

        $plan = $OctopusParameters["planJson"] | ConvertFrom-Json
        $plan | ForEach-Object {
            if (@("aws_instance.clover_worker: Plan to replace", "aws_instance.clover_worker: Plan to update", "aws_instance.clover_worker: Plan to delete").Contains($_."@message"))
            {
                $backup = $true 
            }
        }
    }
    else
    {
        Write-Host "No Terraform output was detected. We're assuming this is because the project has been deployed independantly of the single step."

        # Dummy data to simulate number of changes greater than 1
        $backup = $true
    }

    # If there are changes, backup database and upload to S3
    if ($backup)
    {
        $backupDirectory = New-Item -Type Directory -Path "$($env:SYSTEMDRIVE)\Windows\Temp\$((Get-Date).ToFileTimeUtc())-CDXMETABACKUP"
        Write-Host "Performing backup of CloverDX_META database at $($backupDirectory.FullName)"
        Write-Host "-------"

        $backupFilePath = $(Join-Path -Path $backupDirectory.FullName -ChildPath "backup.bak")
        $backupLogPath = $(Join-Path -Path $backupDirectory.FullName -ChildPath "backup.trn")

        @{"BackupFile"=$backupFilePath;"BackupAction"="Database"},@{"BackupFile"=$backupLogPath;"BackupAction"="Log"} | ForEach-Object {
            Write-Host "Backing up $($_.BackupAction)"
            $backupParams = @{
                "BackupFile"      = $_.BackupFile
                "BackupAction"    = $_.BackupAction
                "Credential"      = Get-DbCredentials
                "Database"        = "CloverDX_META"
                "ServerInstance"  = "localhost"
            }

            Backup-SqlDatabase @backupParams
        }

        $archivePath = "$($backupDirectory.FullName)" + ".zip"
        Compress-Archive -Path $backupDirectory -DestinationPath $archivePath

        if (Test-Path $archivePath)
        {
            Write-S3Object -BucketName "$($($EnvironmentName).ToLower())-cloverdx-meta-backups" -File $archivePath -Key "cloverdx-meta-backup-$((Get-Date).ToFileTimeUtc())"
        }
        else
        {
            throw "No backup ZIP archive found at $($backupDirectory.FullName).zip"
        }
    }
    else
    {
        Write-Host "No changes to CloverDX Worker Node detected in plan output. Not doing anything."
    }
}


Start-CloverDXMetaBackup -EnvironmentName $OctopusParameters["Octopus.Deployment.Tenant.Name"] -AWSRegion $aws_region