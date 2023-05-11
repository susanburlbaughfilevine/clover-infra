Configuration WorkerNode
{
    param 
    (
        [Parameter(Mandatory)]
        [string]$InstallUser
    )

    Import-DSCResource -ModuleName NetworkingDsc -ModuleVersion 9.0.0
    Import-DscResource -Module cChoco -ModuleVersion 2.5.0.0
    Import-DscResource -ModuleName 'SqlServerDsc' -ModuleVersion 16.1.0
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'
    Import-Module clover-powershell
    Import-Module AWSPowershell
    Import-Module SqlServer

    Node localhost
    {

        $getEnvironment = {
            $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content            
            $instance = Get-EC2Instance -InstanceId $instanceId
            $tag = $instance.Instances.Tags.Where({ $_.Key -eq "env" }).Value
            return $tag
        }

        Script RenameComputerScript {
            SetScript  = {
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content
                $TagName = ((Get-EC2Instance -InstanceId $instanceId).Instances[0].Tag | ? { $_.key -eq 'Name' }).Value
                $instanceName = $TagName.SubString(0, 15)                
                if ($instanceName -notmatch "^$($env:COMPUTERNAME)$") {
                    Write-Verbose "Setting the name to $instanceName"                   
                    Rename-Computer -NewName "$instanceName" -Force
                }
            }
            TestScript = {
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content
                $TagName = ((Get-EC2Instance -InstanceId $instanceId).Instances[0].Tag | ? { $_.key -eq 'Name' }).Value
                $instanceName = $TagName.SubString(0, 15)          
                if ($instanceName -match "^$($env:COMPUTERNAME)$") {
                    return $true
                }
                else {
                    return $false
                }
            }

            GetScript  = { @{ Result = ($env:COMPUTERNAME) } }
        }

        
        PendingReboot AfterRenameComputer {
            Name      = 'AfterRenameComputer'
            DependsOn = '[Script]RenameComputerScript'
        }
        

        Script SftEthernetAssignment {
            SetScript  = {
                $activeEthernetInterface = (Get-NetAdapter) | Where { ($_.InterfaceDescription -like "Amazon Elastic Network Adapter*") } | Select-Object -First 1 Name
                $activeEthernetInterfaceName = $activeEthernetInterface.name
                "`nAccessInterface: $activeEthernetInterfaceName" | Out-File -Encoding "utf8" -append "C:\Windows\System32\config\systemprofile\AppData\Local\ScaleFT\sftd.yaml"
                Restart-Service *scaleft*
            }
            TestScript = {
                (Get-Content "C:\Windows\System32\config\systemprofile\AppData\Local\ScaleFT\sftd.yaml" | Select-String -Pattern "AccessInterface" -AllMatches).Count -eq 1
            }
            GetScript  = { @{ Result = Get-Content "C:\Windows\System32\config\systemprofile\AppData\Local\ScaleFT\sftd.yaml" } }
        }

        Script NewRelicAgentEnabled {
            GetScript  = {
                $progData = [Environment]::GetFolderPath('CommonApplicationData')
                $configPath = Join-Path -Path $progData -ChildPath 'New Relic\.NET Agent\newrelic.config'
                $conf = [xml](Get-Content -LiteralPath $configPath -Raw)
                return @{Result = [bool]$conf.configuration.agentEnabled }
            }
    
            SetScript  = {
                $AgentEnabled = $true
                $progData = [Environment]::GetFolderPath('CommonApplicationData')
                $configPath = Join-Path -Path $progData -ChildPath 'New Relic\.NET Agent\newrelic.config'
                $conf = [xml](Get-Content -LiteralPath $configPath -Raw)
                $conf.configuration.agentEnabled = ([string]$AgentEnabled).ToLower()
                $conf.Save($configPath)
            }
    
            TestScript = {
                $AgentEnabled = $true
                $progData = [Environment]::GetFolderPath('CommonApplicationData')
                $configPath = Join-Path -Path $progData -ChildPath 'New Relic\.NET Agent\newrelic.config'
                $conf = [xml](Get-Content -LiteralPath $configPath -Raw)
                $conf.configuration.agentEnabled -eq ([string]$AgentEnabled).ToLower()
            }
        }

        Service NewRelicSvc {
            Name        = 'newrelic-infra'
            StartupType = 'Automatic'
            State       = 'Running'
        }

        User cloverEtlLogin {
            #DependsOn = "[script]CloverEtlSecret"
            Ensure   = "Present"
            UserName = "clover_etl_login"
            Password = Get-CloverEtlUserSecret
        }

        Group cloverEtlAsAdministrator {
            DependsOn        = "[User]cloverEtlLogin"
            Ensure           = "Present"
            GroupName        = "Administrators"
            MembersToInclude = "clover_etl_login"
        }

        Script ConfigureSSH {
            SetScript  = {
                $configPath = "$env:ProgramData\ssh\sshd_config"
                $sshdConfig = Get-Content $configPath
                $sshdConfig = $sshdConfig.Replace("AllowUsers Administrator", "AllowGroups Administrators")
                $sshdConfig | Out-File -FilePath "$env:ProgramData\ssh\sshd_config" -Encoding utf8 -Force
                Restart-Service -Name sshd
            }

            TestScript = {
                if (-not (Test-Path "$env:ProgramData\ssh\sshd_config")) {
                    return $false
                }
                (Get-Content "$env:ProgramData\ssh\sshd_config").Contains("AllowGroups Administrators")  
            }

            GetScript  = {
                if (-not (Test-Path "$env:ProgramData\ssh\sshd_config")) {
                    return [hashtable]@{
                        "Result" = ""
                    }
                }
                
                return [hashtable]@{
                    "Result" = (Get-Content "$env:ProgramData\ssh\sshd_config")
                }
            }
        }


        cChocoPackageInstaller SqlServer {
            DependsOn = "[User]cloverEtlLogin"
            Ensure    = "Present"
            Name      = "sql-server-2019"
            Params    = "'/SQLSYSADMINACCOUNTS:$($InstallUser) /SQLSVCACCOUNT:"".\$($InstallUser)"" /SQLSVCPASSWORD='$(Get-CloverEtlUserSecret -AsPlainText)' /IgnorePendingReboot'"
        }

        cChocoPackageInstaller SqlServerCU {
            DependsOn = "[cChocoPackageInstaller]SqlServer"
            Ensure    = "Present"
            Name      = "sql-server-2019-cumulative-update"
        }

        Script EnableMSSQLTcp {
            # Issues running this script may be related to failures in the SqlServer install.
            # Verify that SqlServer installed succesfully as a first step to troubleshooting
            # errors here
            DependsOn  = "[cChocoPackageInstaller]SqlServerCU"
            SetScript  = {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')
                $wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' localhost
                $tcp = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
                $tcp.IsEnabled = $true
                $tcp.Alter()
            }
            TestScript = {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')
                $wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' localhost
                $tcp = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
                $tcp.IsEnabled
            }
            GetScript  = {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | Out-Null
                $wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' localhost
                $tcp = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
                [hashtable]@{
                    "Result" = $tcp
                }
            }
        }

        Script RestartMSSQLService {
            PsDscRunAsCredential = Get-CloverEtlUserSecret
            DependsOn            = "[Script]EnableMSSQLTcp", "[Registry]LoginMode", "[Firewall]MSSQLPort"
            SetScript            = {
                Start-Sleep -Seconds 180
                New-Item -Type File -Path "$($env:SystemDrive)\dsc\serviceRestarted.tmp"
                Restart-Service -Name MSSQLSERVER -Force
            }
            GetScript            = {
                [hashtable]@{
                    "Result" = (Get-Service MSSQLSERVER)
                }
            }
            TestScript           = {
                if (Test-Path "$($env:SystemDrive)\dsc\serviceRestarted.tmp") {
                    Write-Host "MSSQL Service has already been restarted successfully"
                    return $true
                }
                else {
                    Write-Host "MSSQL Service will be restarted"
                    return $false
                }
            }
        }

        Registry LoginMode {
            DependsOn = "[cChocoPackageInstaller]SqlServer"
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer"
            ValueName = "LoginMode"
            ValueData = 2
            ValueType = "Dword"
        }
        

        Firewall MSSQLPort {
            DependsOn   = "[cChocoPackageInstaller]SqlServer"
            Ensure      = "Present"
            Enabled     = "True"
            Name        = "sql-server-in"
            DisplayName = "sql-server-in"
            LocalPort   = 1433
            Direction   = "Inbound"
            Action      = "Allow"
            Protocol    = "tcp" 
        }      

        ########################
        # FixPermissions
        ########################
        Script FixPermissions {
            PsDscRunAsCredential = Get-CloverEtlUserSecret
            DependsOn            = "[Script]RestoreCloverDxMetaBackup", "[PendingReboot]AfterRenameComputer"
            SetScript            = {
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content

                $TagName = ((Get-EC2Instance -InstanceId $instanceId).Instances[0].Tag | ? { $_.key -eq 'Name' }).Value
                $instanceName = $TagName.SubString(0, 15)    

                $Query = "
                USE [CloverDX_META]
                IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'TempUser') 
                BEGIN
                    CREATE USER TempUser WITHOUT LOGIN;
                END

                ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [TempUser]
                ALTER AUTHORIZATION ON SCHEMA::[db_datareader] TO [TempUser]
                ALTER AUTHORIZATION ON SCHEMA::[db_datawriter] TO [TempUser]
                ALTER AUTHORIZATION ON SCHEMA::[db_accessadmin] TO [TempUser]
                GO
                
                DROP USER IF EXISTS clover_etl_login
                GO
                
                EXEC sp_changedbowner '$instanceName\clover_etl_login'
                GO
                
                IF EXISTS
                (
                    SELECT * FROM sys.server_principals
                    WHERE name = 'clover_etl_login' AND type_desc = 'SQL_LOGIN'
                )
                BEGIN
                    DROP LOGIN clover_etl_login
                END
                
                CREATE LOGIN clover_etl_login
                    WITH PASSWORD='$(Get-CloverEtlUserSecret -AsPlainText)',
                    DEFAULT_DATABASE = master

                ALTER SERVER ROLE [sysadmin] ADD MEMBER [clover_etl_login]
                
                CREATE USER clover_etl_login FOR LOGIN clover_etl_login
                ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [clover_etl_login]
                ALTER AUTHORIZATION ON SCHEMA::[db_datareader] TO [clover_etl_login]
                ALTER AUTHORIZATION ON SCHEMA::[db_datawriter] TO [clover_etl_login]
                ALTER AUTHORIZATION ON SCHEMA::[db_accessadmin] TO [clover_etl_login]
                ALTER ROLE [db_owner] ADD MEMBER [clover_etl_login]
                GO

                EXEC sp_configure 'show advanced options', '1'
                RECONFIGURE

                EXEC sp_configure 'xp_cmdshell', '1' 
                RECONFIGURE

                IF NOT EXISTS (SELECT * FROM sys.extended_properties WHERE name ='instance')
                BEGIN
                    EXEC sys.sp_addextendedproperty
                    @name  = N'instance',
                    @value = N'$instanceId'
                END
                ELSE
                BEGIN
                    EXEC sys.sp_updateextendedproperty
                    @name  = N'instance',
                    @value = N'$instanceId'
                END
                GO
            "
                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }

                $dbExists = (Invoke-Sqlcmd -TrustServerCertificate @testParams)
                
                return [hashtable]@{
                    "Result" = "CloverDX Meta exists: $dbExists"
                }
 
            }

            GetScript            = {
                $cred = Get-CloverEtlUserSecret
                $Query = "
                USE [CloverDX_META]
                SELECT * FROM sys.database_principals WHERE name = 'TempUser'
                GO
            "
                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }

                $dbExists = (Invoke-Sqlcmd -TrustServerCertificate @testParams)
                
                return [hashtable]@{
                    "Result" = "CloverDX Meta exists: $dbExists"
                }
            }

            TestScript           = {
                $cred = Get-CloverEtlUserSecret
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content

                $query = "
                    USE [CloverDX_META]
                    SELECT value As InstanceId
                    FROM sys.extended_properties WHERE name = 'instance'
                "
                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }

                $dbInstanceId = (Invoke-Sqlcmd -TrustServerCertificate @testParams).InstanceId

                if ($instanceId -match "^$dbInstanceId$") {
                    return $true
                }
                else {
                    return $false
                }
            }
        }

        ########################
        # CreateMetalUser
        ########################
        Script CreateMetalUser {
            PsDscRunAsCredential = Get-CloverEtlUserSecret
            DependsOn            = "[Script]FixPermissions"
            SetScript            = {

                $Query = "
                USE [master]
                SET ANSI_NULLS ON
                GO
                SET QUOTED_IDENTIFIER ON
                GO
            
                /*METAL_User Role*/
                IF NOT EXISTS(SELECT 1 FROM sys.server_principals WHERE name = 'METAL_User')
                    BEGIN
                        CREATE SERVER ROLE [METAL_User];
                        ALTER SERVER ROLE [securityadmin] ADD MEMBER [METAL_User]
                        ALTER SERVER ROLE [serveradmin] ADD MEMBER [METAL_User]
                        ALTER SERVER ROLE [setupadmin] ADD MEMBER [METAL_User]
                        ALTER SERVER ROLE [processadmin] ADD MEMBER [METAL_User]
                        ALTER SERVER ROLE [diskadmin] ADD MEMBER [METAL_User]
                        ALTER SERVER ROLE [dbcreator] ADD MEMBER [METAL_User]
                        ALTER SERVER ROLE [bulkadmin] ADD MEMBER [METAL_User]
                    END
                "

                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }

                $dbExists = (Invoke-Sqlcmd -TrustServerCertificate @testParams)
                
                return [hashtable]@{
                    "Result" = "CloverDX Meta exists: $dbExists"
                }
 
            }

            GetScript            = {
                $cred = Get-CloverEtlUserSecret
                $Query = "
                SELECT count(*) as UserCount 
                FROM sys.server_principals WHERE name = 'METAL_User'
            "
                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }

                $dbExists = (Invoke-Sqlcmd -TrustServerCertificate @testParams).UserCount
                
                return [hashtable]@{
                    "Result" = "METAL_User exists: $dbExists"
                }
            }

            TestScript           = {
                $cred = Get-CloverEtlUserSecret
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content

                $query = "
                USE [master]
                SELECT count(*) as UserCount 
                FROM sys.server_principals WHERE name = 'METAL_User'
                "
                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }


                $UserCount = (Invoke-Sqlcmd -TrustServerCertificate @testParams).UserCount

                if ($UserCount -eq 1) {
                    return $true
                }
                else {
                    return $false
                }
            }
        }      
        

        ########################
        # AlterMetalUserRole
        ########################
        Script AlterMetalUserRole {
            PsDscRunAsCredential = Get-CloverEtlUserSecret
            DependsOn            = "[Script]CreateMetalUser"
            SetScript            = {
                $Query = "
                ALTER SERVER ROLE METAL_User ADD MEMBER clover_etl_login
            "

                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }

                $dbExists = (Invoke-Sqlcmd -TrustServerCertificate @testParams)
                
                return [hashtable]@{
                    "Result" = "CloverDX Meta exists: $dbExists"
                }
 
            }

            GetScript            = {
                $cred = Get-CloverEtlUserSecret
                $Query = "
                SELECT roles.principal_id AS RolePrincipalID,
                roles.name AS RolePrincipalName,
                server_role_members.member_principal_id AS MemberPrincipalID,
                members.name AS MemberPrincipalName
         FROM sys.server_role_members AS server_role_members
             INNER JOIN sys.server_principals AS roles
                 ON server_role_members.role_principal_id = roles.principal_id
             INNER JOIN sys.server_principals AS members
                 ON server_role_members.member_principal_id = members.principal_id     
            "


                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }

                $dbExists = (Invoke-Sqlcmd -TrustServerCertificate @testParams)
                
                return [hashtable]@{
                    "Result" = "CloverDX Meta exists: $dbExists"
                }
            }

            TestScript           = {
                $cred = Get-CloverEtlUserSecret
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content

                $query = "
                SELECT count(*) MemberPrincipalName
                FROM
                (
                    SELECT roles.principal_id AS RolePrincipalID,
                           roles.name AS RolePrincipalName,
                           server_role_members.member_principal_id AS MemberPrincipalID,
                           members.name AS MemberPrincipalName
                    FROM sys.server_role_members AS server_role_members
                        INNER JOIN sys.server_principals AS roles
                            ON server_role_members.role_principal_id = roles.principal_id
                        INNER JOIN sys.server_principals AS members
                            ON server_role_members.member_principal_id = members.principal_id
                ) AS SUBQUERY
                WHERE RolePrincipalName = 'METAL_user'
                "
                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = $Query
                }


                $UserCount = (Invoke-Sqlcmd -TrustServerCertificate @testParams).MemberPrincipalName

                if ($UserCount -eq 1) {
                    return $true
                }
                else {
                    return $false
                }
            }
        }              

        ########################
        # RestoreCloverDxMetaBackup
        ########################
        Script RestoreCloverDxMetaBackup {
            PsDscRunAsCredential = Get-CloverEtlUserSecret
            DependsOn            = "[Script]RestartMSSQLService", "[PendingReboot]AfterRenameComputer"
            SetScript            = {
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content            
                $instance = Get-EC2Instance -InstanceId $instanceId         
                $env =  $instance.Instances.Tags.Where({ $_.Key -eq "env" }).Value

                # Grab most recent backup file
                $backupObject = Get-S3Object -BucketName "$($($env).ToLower())-cloverdx-meta-backups" | Sort-Object LastModified -Descending | Select-Object -First 1
                $backupObject | Read-S3Object -File "$($env:SystemDrive)\Windows\Temp\backup.zip"
                Expand-Archive -Path "$($env:SystemDrive)\Windows\Temp\backup.zip" -DestinationPath "$($env:SystemDrive)\Windows\Temp\backup" -Force
                
                $acl = Get-Acl "$($env:SystemDrive)\Windows\Temp\backup"
                $perm = "NT Service\MSSQLSERVER", "Write, Read, ReadAndExecute", "Allow"
                $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
                $acl.SetAccessRule($rule)
                $acl | Set-Acl -Path "$($env:SystemDrive)\Windows\Temp\backup"

                $backupFiles = (Get-ChildItem "$($env:SystemDrive)\Windows\Temp\backup" -Recurse)
                
                # If we end up wanting to perform tlog restores as well, add the following string before the pipe below
                # ,@{"Type"="Log";"Path"=$backupFiles.Where({$_.Name.EndsWith(".trn")})
                @{"Type" = "Database"; "Path" = $backupFiles.Where({ $_.Name.EndsWith(".bak") }) } | ForEach-Object {
                    $acl = Get-Acl $_.Path.FullName
                    $perm = "NT Service\MSSQLSERVER", "Write, Read, ReadAndExecute", "Allow"
                    $rule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $perm
                    $acl.SetAccessRule($rule)
                    $acl | Set-Acl -Path $_.Path.FullName

                    $restoreParams = @{
                        ServerInstance = "localhost"
                        Database       = "CloverDX_META"
                        BackupFile     = $_.Path.FullName
                        RestoreAction  = $_.Type
                    }

                    Restore-SqlDatabase @restoreParams
                }
            }

            GetScript            = {
                $testParams = @{
                    ServerInstance = "localhost"
                    Query          = "SELECT * FROM sys.databases"
                }

                $dbExists = (Invoke-Sqlcmd -TrustServerCertificate @testParams).Name.Contains("CloverDX_META")
                
                return [hashtable]@{
                    "Result" = "CloverDX Meta exists: $dbExists"
                }
            }

            TestScript           = {

                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content            
                $instance = Get-EC2Instance -InstanceId $instanceId         
                $env =  $instance.Instances.Tags.Where({ $_.Key -eq "env" }).Value


                $bucket = Get-S3Bucket -BucketName "$($($env).ToLower())-cloverdx-meta-backups"

                if ($null -ne $bucket) {
                    $testParams = @{
                        ServerInstance = "localhost"
                        Query          = "SELECT * FROM sys.databases"
                    }

                    $dbExists = (Invoke-Sqlcmd -TrustServerCertificate @testParams).Name.Contains("CloverDX_META")

                    if ($dbExists) {
                        return $true
                    }
                }

                return $false
            }
        }

    }
}
