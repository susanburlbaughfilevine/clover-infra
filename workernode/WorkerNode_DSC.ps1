Configuration WorkerNode
{
    param 
    (
        [Parameter(Mandatory)]
        [string]$InstallUser
    )

    Import-DSCResource -ModuleName NetworkingDsc
    Import-DscResource -Module cChoco
    Import-DscResource -ModuleName 'SqlServerDsc'

    Node localhost
    {

        User cloverEtlLogin
        {
            DependsOn = "[script]CloverEtlSecret"
            Ensure = "Present"
            UserName = "clover_etl_login"
            Password = $(
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
                New-Object System.Management.Automation.PSCredential $InstallUser, $password
            )
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

        SqlLogin AddCloverEtlLogin
        {
            DependsOn = "[cChocoPackageInstaller]SqlServer"
            Ensure          = "Present"
            LoginMustChangePassword =  $false
            Name            = "clover_etl_login"
            LoginType       = "SqlLogin"
            ServerName      = "localhost"
            InstanceName    = "MSSQLSERVER"
            DefaultDatabase = "master"
            LoginCredential = $(
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
                New-Object System.Management.Automation.PSCredential $InstallUser, $password
            )
        }

        SqlScriptQuery CreateMetalUser
        {
            DependsOn = "[cChocoPackageInstaller]SqlServer"
            ServerName = "localhost"
            InstanceName = "MSSQLSERVER"
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
                SELECT 1 FROM sys.server_principals WHERE name = 'METAL_User'
                GO
            "
            GetQuery = "
                USE [master]
                SELECT 1 FROM sys.server_principals WHERE name = 'METAL_User'
                GO
            "
        }

        SqlScriptQuery AlterMetalUserRole
        {
            DependsOn    = "[SqlScriptQuery]CreateMetalUser"
            ServerName   = "localhost"
            InstanceName = "MSSQLSERVER"
            SetQuery     = "ALTER SERVER ROLE METAL_User ADD MEMBER clover_etl_login"
            TestQuery    = "
                SELECT MemberPrincipalName 
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
                WHERE RolePrincipalName = 'METAL_user'
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
    }
}

$global:DSCMachineStatus = 1

workernode -InstallUser $InstallUser -ConfigurationData $ConfigData
Start-DSCConfiguration ./workernode -Wait -Force