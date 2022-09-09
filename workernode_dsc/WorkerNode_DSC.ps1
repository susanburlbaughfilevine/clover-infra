Configuration WorkerNode
{
    param 
    (
        [Parameter(Mandatory)]
        [string]$InstallUser
    )

    Import-DSCResource -ModuleName NetworkingDsc -ModuleVersion 9.0.0
    Import-DscResource -Module cChoco -ModuleVersion 2.5.0.0
    Import-DscResource -ModuleName 'SqlServerDsc' -ModuleVersion 16.0.0
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'


    Node localhost
    {
        # Function for retriving Windows/SQL Login clover_etl_login credentials for use in the following DSC resources
        $getCredentials = {
            Import-Module AWSPowershell
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

        $getPlainTextCredentials = {
            Import-Module AWSPowershell
            $filter = [Amazon.SecretsManager.Model.Filter]@{
                "Key"    = "Name"
                "Values" = "cloveretl-ssh-credentials"
            }
        
            $secSecret = Get-SECSecretList -Filter $filter | Select-Object -First 1
        
            if ($null -eq $secSecret) {
                return $false
            }
            
            $password = ((Get-SECSecretValue -SecretId $secSecret.name).SecretString | ConvertFrom-Json).password
            return $password
        }

        # Using something here like $ENV:ComputerName does not work because functions are executed at compile time and not run time, 
        # so the computer name will NOT be correct
        $getTagName = {
            $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content
            $instanceName = ((Get-EC2Instance -InstanceId $instanceId).Instances[0].Tag | ? {$_.key -eq 'Name'}).Value
            return ($instanceName.SubString(0,15))
        }

        # Why does the below function exist? Because Invoke-SqlCmd, used by the SqlScriptQuery DSC resource, is unable to handle
        # special characters passed as a variable into the script. So, we have to resort to this. Trust me when I say that I would
        # much rather use the variable parameter.

        $getSetQuery = {
            $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content

            $query = "
                USE [CloverDX_META]
                IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'TempUser') BEGIN
                    CREATE USER TempUser WITHOUT LOGIN;
                END

                ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [TempUser]
                ALTER AUTHORIZATION ON SCHEMA::[db_datareader] TO [TempUser]
                ALTER AUTHORIZATION ON SCHEMA::[db_datawriter] TO [TempUser]
                ALTER AUTHORIZATION ON SCHEMA::[db_accessadmin] TO [TempUser]
                GO
                
                DROP USER IF EXISTS clover_etl_login
                GO
                
                EXEC sp_changedbowner '##HOSTNAME##\clover_etl_login'
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
                    WITH PASSWORD='##PASSWORD##',
                    DEFAULT_DATABASE = master
                
                CREATE USER clover_etl_login FOR LOGIN clover_etl_login
                ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [clover_etl_login]
                ALTER AUTHORIZATION ON SCHEMA::[db_datareader] TO [clover_etl_login]
                ALTER AUTHORIZATION ON SCHEMA::[db_datawriter] TO [clover_etl_login]
                ALTER AUTHORIZATION ON SCHEMA::[db_accessadmin] TO [clover_etl_login]
                ALTER ROLE [db_owner] ADD MEMBER [clover_etl_login]
                GO

                IF NOT EXISTS (SELECT * FROM sys.extended_properties WHERE name ='instance')
                BEGIN
                    EXEC sys.sp_addextendedproperty
                    @name  = N'instance',
                    @value = N'##INSTANCEID##'
                END
                ELSE
                BEGIN
                    EXEC sys.sp_updateextendedproperty
                    @name  = N'instance',
                    @value = N'##INSTANCEID##'
                END
                GO
            "

            $query = $query.Replace("##PASSWORD##", $(& $getPlainTextCredentials)).Replace("##HOSTNAME##", $(& $getTagName)).Replace("##INSTANCEID##", $instanceId)
            return $query
        }

        $getTestQuery = {
            $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content

            $query = "
                USE [CloverDX_META]
                if (SELECT value FROM sys.extended_properties WHERE name = 'instance') = '##INSTANCEID##'
                BEGIN
                    PRINT 'Already executed for instance ##INSTANCEID##'
                END
                ELSE
                BEGIN
                    RAISERROR ('FixPermissions has not yet run for instance ##INSTANCEID##',16,1)
                END
                GO
            "

            $query = $query.Replace("##INSTANCEID##", $instanceId)
            return $query
        }

        # Function for getting the environment name from EC2 instance tags
        $getEnvironment = {
            $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content
            $instance = Get-EC2Instance -InstanceId $instanceId
            $tag = $instance.Instances.Tags.Where({$_.Key -eq "env"}).Value
            return $tag
        }

        Script RenameComputerScript
        {
            SetScript = {
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content
                $instanceName = ((Get-EC2Instance -InstanceId $instanceId).Instances[0].Tag | ? {$_.key -eq 'Name'}).Value
                Write-Verbose "Setting the name to $instanceName"
                Rename-Computer -NewName "$instanceName" -Force
            }
            TestScript = {
                $instanceId = (iwr http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing | select content).content
                $instanceName = ((Get-EC2Instance -InstanceId $instanceId).Instances[0].Tag | ? {$_.key -eq 'Name'}).Value
                Write-Verbose "Checking if $instanceName matches $env:COMPUTERNAME"
                $instanceName -match $env:COMPUTERNAME
            }
            GetScript = { @{ Result = ($env:COMPUTERNAME) } }
        }

        PendingReboot AfterRenameComputer {
            Name = 'AfterRenameComputer'
            DependsOn = '[Script]RenameComputerScript'
        }

        Script SftEthernetAssignment
        {
            SetScript = {
                $activeEthernetInterface = (Get-NetAdapter) | Where {($_.InterfaceDescription -like "Amazon Elastic Network Adapter*")} | Select-Object -First 1 Name
                $activeEthernetInterfaceName = $activeEthernetInterface.name
                "`nAccessInterface: $activeEthernetInterfaceName" | Out-File -Encoding "utf8" -append "C:\Windows\System32\config\systemprofile\AppData\Local\ScaleFT\sftd.yaml"
                Restart-Service *scaleft*
            }
            TestScript = {
                (Get-Content "C:\Windows\System32\config\systemprofile\AppData\Local\ScaleFT\sftd.yaml" | Select-String -Pattern "AccessInterface" -AllMatches).Count -eq 1
            }
            GetScript = { @{ Result = Get-Content "C:\Windows\System32\config\systemprofile\AppData\Local\ScaleFT\sftd.yaml" } }
        }

        Script NewRelicAgentEnabled
        {
            GetScript = {
                $progData = [Environment]::GetFolderPath('CommonApplicationData')
                $configPath = Join-Path -Path $progData -ChildPath 'New Relic\.NET Agent\newrelic.config'
                $conf = [xml](Get-Content -LiteralPath $configPath -Raw)
                return @{Result = [bool]$conf.configuration.agentEnabled}
            }
    
            SetScript = {
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

        Service NewRelicSvc
        {
            Name        = 'newrelic-infra'
            StartupType = 'Automatic'
            State       = 'Running'
        }

        User cloverEtlLogin
        {
            DependsOn = "[script]CloverEtlSecret"
            Ensure = "Present"
            UserName = "clover_etl_login"
            Password = & $getCredentials
        }

        Group cloverEtlAsAdministrator
        {
            DependsOn = "[User]cloverEtlLogin"
            Ensure    = "Present"
            GroupName = "Administrators"
            MembersToInclude = "clover_etl_login"
        }

        Script ConfigureSSH
        {
            SetScript = {
                $configPath = "$env:ProgramData\ssh\sshd_config"
                $sshdConfig = Get-Content $configPath
                $sshdConfig = $sshdConfig.Replace("AllowUsers Administrator","AllowGroups Administrators")
                $sshdConfig | Out-File -FilePath "$env:ProgramData\ssh\sshd_config" -Encoding utf8 -Force
            }

            TestScript = {
                if (-not (Test-Path "$env:ProgramData\ssh\sshd_config")) {
                    return $false
                }

                (Get-Content "$env:ProgramData\ssh\sshd_config").Contains("AllowGroups Administrators")  
            }

            GetScript = {
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

        Script CloverEtlSecret
        {
            SetScript = {
                Import-Module AWSPowershell

                $filter = [Amazon.SecretsManager.Model.Filter]@{
                    "Key"    = "Name"
                    "Values" = "cloveretl-ssh-credentials"
                }
                
                $password = Get-SECRandomPassword

                $secSecret = Get-SECSecretList -Filter $filter

                $updateParams = @{
                    "SecretString" = (@{"password"=$($password)} | ConvertTo-Json)
                    "Description"  = "Password for the clover_etl_login user"
                    "SecretId"     = $secSecret.ARN
                }

                Update-SECSecret @updateParams
            }

            TestScript = {
                Import-Module AWSPowershell
                $filter = [Amazon.SecretsManager.Model.Filter]@{
                    "Key"    = "Name"
                    "Values" = "cloveretl-ssh-credentials"
                }

                $secSecret = Get-SECSecretList -Filter $filter | Select-Object -First 1

                if ($null -eq $secSecret) {
                    return $false
                }

                $secretValue = ((Get-SECSecretValue -SecretId $secSecret.name).SecretString | ConvertFrom-Json).password
                
                # We'll make the assumption that if the value is here that it is the right
                # one for the sake of configuration simplicity. Otherwise password has to be
                # generated outside of DSC configuration
                if (([string]::IsNullOrEmpty($secretValue) -eq $false) -or ($secretValue -eq "null")) {
                    return $true
                }

                $false
            }

            GetScript = {
                Import-Module AWSPowershell

                $filter = [Amazon.SecretsManager.Model.Filter]@{
                    "Key"    = "Name"
                    "Values" = "cloveretl-ssh-credentials"
                }

                $secSecret = Get-SECSecretList -Filter $filter | Select-Object -First 1

                if ($null -eq $secSecret) {
                    return [hashtable]@{
			            "Result" = [Amazon.SecretsManager.Model.SecretListEntry]::new()
		            }
                }

	            [hashtable]@{
			        "Result"= (Get-SECSecretValue -SecretId $secSecret.name).SecretString
		        }
            }
        }

        cChocoPackageInstaller SqlServer
        {
            DependsOn = "[User]cloverEtlLogin"
            Ensure = "Present"
            Name   = "sql-server-2019"
            Params = "'/SQLSYSADMINACCOUNTS:$($InstallUser) /IgnorePendingReboot'"
        }

        cChocoPackageInstaller SqlServerCU
        {
            DependsOn = "[cChocoPackageInstaller]SqlServer"
            Ensure    = "Present"
            Name      = "sql-server-2019-cumulative-update"
        }

        Script EnableMSSQLTcp
        {
            DependsOn = "[cChocoPackageInstaller]SqlServer"
            SetScript = {
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
            GetScript = {
                [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement') | Out-Null
                $wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' localhost
                $tcp = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
                [hashtable]@{
			        "Result" = $tcp
		        }
            }
        }

        Script RestartMSSQLService
        {
            PsDscRunAsCredential = & $getCredentials
            DependsOn = "[Script]EnableMSSQLTcp","[Registry]LoginMode","[Firewall]MSSQLPort"
            SetScript = {
                Start-Sleep -Seconds 180
                New-Item -Type File -Path "$($env:SystemDrive)\dsc\serviceRestarted.tmp"
                Restart-Service -Name MSSQLSERVER -Force
            }
            GetScript = {
                [hashtable]@{
			        "Result" = (Get-Service MSSQLSERVER)
		        }
            }
            TestScript = {
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

        Registry LoginMode
        {
            DependsOn = "[cChocoPackageInstaller]SqlServer"
            Ensure      = "Present"
            Key         = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer"
            ValueName   = "LoginMode"
            ValueData   = 2
            ValueType   = "Dword"
        }
        

        Firewall MSSQLPort
        {
            DependsOn = "[cChocoPackageInstaller]SqlServer"
            Ensure      = "Present"
            Enabled     = "True"
            Name        = "sql-server-in"
            DisplayName = "sql-server-in"
            LocalPort   = 1433
            Direction   = "Inbound"
            Action      = "Allow"
            Protocol    = "tcp" 
        }

        SqlScriptQuery FixPermissions
        {
            # Because the CloverDX_META database is restored with an existing clover_etl_login user, we need to recreate the permissions
            # (login and user + each permissions) necessary on the database to make it accessible
            DependsOn = "[Script]RestoreCloverDxMetaBackup", "[PendingReboot]AfterRenameComputer"
            ServerName = "localhost"
            InstanceName = "MSSQLSERVER"
            PsDscRunAsCredential = & $getCredentials
            SetQuery  = & $getSetQuery
            TestQuery = & $getTestQuery
            GetQuery = "
                USE [master]
                SELECT * FROM sys.database_principals WHERE name = 'TempUser'
                GO
            "
        }

        SqlScriptQuery CreateMetalUser
        {
            DependsOn    = "[Script]RestartMSSQLService"
            ServerName   = "localhost"
            InstanceName = "MSSQLSERVER"
            PsDscRunAsCredential = & $getCredentials
            SetQuery = "
                USE [master]
                GO
            
                /****** Object:  StoredProcedure [dbo].[usp_CreateServerRoles]    Script Date: 11/1/2020 12:48:39 PM ******/
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

            TestQuery = "
                USE [master]
                if (SELECT count(*) FROM sys.server_principals WHERE name = 'METAL_User') = 0
                BEGIN
                    RAISERROR ('METAL_User not found',16,1)
                END
                ELSE
                BEGIN
                    PRINT 'Found METAL_USER'
                END
                "
            GetQuery = "
                USE [master]
                SELECT * FROM sys.server_principals WHERE name = 'METAL_User'
                GO
            "
        }

        SqlScriptQuery AlterMetalUserRole
        {
            DependsOn    = "[SqlScriptQuery]FixPermissions"
            ServerName   = "localhost"
            InstanceName = "MSSQLSERVER"
            SetQuery     = "ALTER SERVER ROLE METAL_User ADD MEMBER clover_etl_login"
            PsDscRunAsCredential  = & $getCredentials
            TestQuery    = "
                USE [master]
                if (                
                    SELECT count(*) MemberPrincipalName 
                    FROM
                        (
                            SELECT	roles.principal_id						AS RolePrincipalID
                            ,	roles.name									AS RolePrincipalName
                            ,	server_role_members.member_principal_id		AS MemberPrincipalID
                            ,	members.name								AS MemberPrincipalName
                            FROM sys.server_role_members AS server_role_members
                            INNER JOIN sys.server_principals AS roles
                                ON server_role_members.role_principal_id = roles.principal_id
                            INNER JOIN sys.server_principals AS members 
                                ON server_role_members.member_principal_id = members.principal_id
                        ) AS SUBQUERY
                    WHERE RolePrincipalName = 'METAL_user') = 0
                BEGIN
                    RAISERROR ('Role principal not found',16,1)
                END
                ELSE
                BEGIN
                    PRINT 'Found clover_etl_login as member of METAL_User'
                END
            "
            GetQuery = "
                SELECT	roles.principal_id						    AS RolePrincipalID
                    ,	roles.name									AS RolePrincipalName
                    ,	server_role_members.member_principal_id		AS MemberPrincipalID
                    ,	members.name								AS MemberPrincipalName
                FROM sys.server_role_members AS server_role_members
                INNER JOIN sys.server_principals AS roles
                    ON server_role_members.role_principal_id = roles.principal_id
                INNER JOIN sys.server_principals AS members 
                    ON server_role_members.member_principal_id = members.principal_id
            "
        }

        Script RestoreCloverDxMetaBackup
        {
            PsDscRunAsCredential  = & $getCredentials
            DependsOn = "[Script]RestartMSSQLService"
            SetScript = {
                Install-Module sqlserver -Force -AllowClobber
                $env = Invoke-Expression "$($using:GetEnvironment)"

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
                @{"Type"="Database";"Path"=$backupFiles.Where({$_.Name.EndsWith(".bak")})} | ForEach-Object {
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

            GetScript = {
                Install-Module sqlserver -Force -AllowClobber
                $cred = Invoke-Expression "$($using:getCredentials)"

                $testParams = @{
                    Credential = $cred
                    ServerInstance = "localhost"
                    Query = "SELECT * FROM sys.databases"
                }

                $dbExists = (Invoke-Sqlcmd @testParams).Name.Contains("CloverDX_META")
                
                return [hashtable]@{
                    "Result" = "CloverDX Meta exists: $dbExists"
                }
            }

            TestScript = {
                Install-Module sqlserver -Force -AllowClobber
                $env = Invoke-Expression "$($using:GetEnvironment)"

                $bucket = Get-S3Bucket -BucketName "$($($env).ToLower())-cloverdx-meta-backups"

                if ($null -ne $bucket)
                {
                    $testParams = @{
                        ServerInstance = "localhost"
                        Query = "SELECT * FROM sys.databases"
                    }

                    $dbExists = (Invoke-Sqlcmd @testParams).Name.Contains("CloverDX_META")

                    if ($dbExists)
                    {
                        return $true
                    }
                }

                return $false
            }
        }
    }
}