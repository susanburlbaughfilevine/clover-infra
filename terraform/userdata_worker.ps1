<powershell>

# It can take 20+ minutes for this userdata execution + other instance bootstrapping processes to finish

Remove-WindowsFeature Web-Server

$userdata_start_time = Get-Date

$folder = "c:\dsc\config"
Push-Location $folder

# How do you get the Private IP that is generated from the EC2 Instance?
# Hit the metadata server for info
$ipv4 = (Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/local-ipv4 -UseBasicParsing).Content
$instanceId = (Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing).Content

# Get the value of the 'Name' Tag
# Requires Role Policy ec2DescribeTags
$instanceName = ((Get-EC2Instance -InstanceId $instanceId).Instances[0].Tag | ? {$_.key -eq 'Name'}).Value

Write-Output "ipv4: $ipv4"

# Define a configuration to allow reboot and resume behavior in DSC
[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node "localhost"
    {
        Settings
        {
            RebootNodeIfNeeded = $True
        }
    }
}


# Define a configuration to install Octopus tentacle
# Can be compiled and applied as follows:
# InstallOctopus -ComputerName "<desired Octopus Display Name here>"
# Start-DscConfiguration -Path .\InstallOctopus\ -Verbose -Wait -Force
Configuration InstallOctopus
{
    param
    (
        [String]
        $ComputerName=$(hostname)
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDsc'
    Import-DscResource -ModuleName 'OctopusDSC'

    cTentacleAgent OctopusTentacle
    {
        Ensure = "Present"
        State = "Started"
        # Tentacle instance name. Leave it as 'Tentacle' unless you have more
        # than one instance
        Name = "Tentacle"
        # Use internal comms
        DisplayName = "$ComputerName"
        PublicHostNameConfiguration = "Custom"
        CustomPublicHostName = "$ipv4"
        # Configure project space
        Space = "${octopus_space}"
        # Registration - all parameters required
        ApiKey = "${octopus_api_key}"
        OctopusServerUrl = "${octopus_server_address}"
        Environments = "${octopus_server_environment}"
        Tenants = "${octopus_tenant}"
        Roles = "${server_roles}"
    }
}

# Don't use the Default RenameComputer DSC as of 3 Mar 2020 as it limits to 15 char password
# Default to setting the compiled configuration to current computer name.  Pass a name in to change it.
Configuration ScriptRenameComputer
{
    param
    (
        [String]
        $NewComputerName
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'

    Node localhost
    {
        Script RenameComputerScript
        {
            SetScript = {
                Write-Verbose "Setting the name to $using:NewComputerName"
                Rename-Computer -NewName "$using:NewComputerName" -Force
            }
            TestScript = {
                Write-Verbose "Checking if $using:NewComputerName matches $env:COMPUTERNAME"
                $using:NewComputerName -match $env:COMPUTERNAME
            }
            GetScript = { @{ Result = ($env:COMPUTERNAME) } }
        }

        PendingReboot AfterRenameComputer {
            Name = 'AfterRenameComputer'
            DependsOn = '[Script]RenameComputerScript'
        }
    }
}

Install-Module xPsDesiredStateConfiguration -Force -Verbose


Configuration SftEthernetAssignment
    {
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DscResource -ModuleName 'ComputerManagementDSC'

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
}

Configuration NewRelicInfraAgent
{
    param(
        [Parameter(Mandatory)]
        [string]$StartupType,

        [Parameter(Mandatory)]
        [string]$State
    )

    Service NewRelicSvc
    {
        Name        = 'newrelic-infra'
        StartupType = $StartupType
        State       = $State
    }
}

Configuration NewRelicNetAgent
{
    param(
        [Parameter(Mandatory)]
        [bool]$AgentEnabled
    )

    Script NewRelicAgentEnabled
    {
        GetScript = {
            $progData = [Environment]::GetFolderPath('CommonApplicationData')
            $configPath = Join-Path -Path $progData -ChildPath 'New Relic\.NET Agent\newrelic.config'
            $conf = [xml](Get-Content -LiteralPath $configPath -Raw)
            return @{Result = [bool]$conf.configuration.agentEnabled}
        }

        SetScript = {
            $progData = [Environment]::GetFolderPath('CommonApplicationData')
            $configPath = Join-Path -Path $progData -ChildPath 'New Relic\.NET Agent\newrelic.config'
            $conf = [xml](Get-Content -LiteralPath $configPath -Raw)
            $conf.configuration.agentEnabled = ([string]$using:AgentEnabled).ToLower()
            $conf.Save($configPath)
        }

        TestScript = {
            $progData = [Environment]::GetFolderPath('CommonApplicationData')
            $configPath = Join-Path -Path $progData -ChildPath 'New Relic\.NET Agent\newrelic.config'
            $conf = [xml](Get-Content -LiteralPath $configPath -Raw)
            $conf.configuration.agentEnabled -eq ([string]$using:AgentEnabled).ToLower()
        }
    }
}

# Execute AllInOne Module made up of combined modules from above.
Configuration AllInOne {
    param (
        [Parameter(Mandatory)]
        [string]$newcomputername,

        [Parameter(Mandatory)]
        [string]$NrStartupType,

        [Parameter(Mandatory)]
        [string]$NrState,

        [Parameter(Mandatory)]
        [bool]$NrNetEnabled
        )

    node localhost {

        ScriptRenameComputer myrename
		{
            NewComputerName = $newcomputername
        }

        InstallOctopus mytentacle
        {
            ComputerName = $newcomputername
        }

        SftEthernetAssignment EthernetAssignment {}

        NewRelicInfraAgent nrinfra
        {
            StartupType = $NrStartupType
            State = $NrState
        }

        NewRelicNetAgent nrnet
        {
            AgentEnabled = $NrNetEnabled
        }
    }
}

# Begin LCM for management of reboots
LCMConfig
Set-DscLocalConfigurationManager -Path .\LCMConfig -Verbose

# Enable rebooting if needed
$global:DSCMachineStatus = 1

$nrState = 'Stopped'
$nrStartupType = 'Disabled'
$nrNetEnabled = $false
if ("${newrelic_enabled}" -eq 'true')
{
    $nrState = 'Running'
    $nrStartupType = 'Automatic'
    $nrNetEnabled = $true
}

[Reflection.Assembly]::LoadWithPartialName("System.Web")
$password = [System.Web.Security.Membership]::GeneratePassword(14,2)
net user clover_etl_login $password /add /active:yes
net localgroup administrators /add clover_etl_login

$configPath = "$env:ProgramData\ssh\sshd_config"
$sshdConfig = Get-Content $configPath
$sshdConfig = $sshdConfig.Replace("AllowUsers Administrator","AllowGroups Administrators") 
$sshdConfig | Out-File -FilePath "$env:ProgramData\ssh\sshd_config" -Encoding utf8 -Force

$filter = [Amazon.SecretsManager.Model.Filter]@{
    "Key"    = "Name"
    "Values" = "${octopus_tenant}-cloveretl-ssh-credentials"
}

$secSecret = Get-SECSecretList -Filter $filter

$updateParams = @{
    "SecretString" = $password
    "Description"  = "Password for the clover_etl_login user"
    "SecretId"     = $secSecret.ARN
}

Update-SECSecret @updateParams

choco install -y sql-server-2019 --params "'/SQLSYSADMINACCOUNTS:clover_etl_login /IgnorePendingReboot'" 

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')

$wmi = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer' localhost

$tcp = $wmi.ServerInstances['MSSQLSERVER'].ServerProtocols['Tcp']
$tcp.IsEnabled = $true  
$tcp.Alter()

Restart-Service -Name MSSQLSERVER -Force

$sqlFirewallRuleCreate = @{
    "Name"        = "sql-server-in"
    "DisplayName" = "sql-server-in"
    "LocalPort"   = 1433
    "Protocol"    = "tcp"
    "Direction"   = "Inbound"
    "Action"      = "Allow"
}

New-NetFirewallRule @sqlFirewallRuleCreate

$securePass = ConvertTo-SecureString $password -AsPlainText -Force
$username = "clover_etl_login"
$credential = New-Object System.Management.Automation.PSCredential $username, $securePass

$createMetalRole = @'
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
'@

$changeLoginMode = @'
    USE [master]
    GO
    EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
        N'Software\Microsoft\MSSQLServer\MSSQLServer',
        N'LoginMode', REG_DWORD, 2
    GO
'@

$nativeSqlCommands = @'
    param (
        [string]$password
    )

    #Temporary debug logging
    write-host "password is : $password"

    $securePass = ConvertTo-SecureString $password -AsPlainText -Force
    write-host "Created secure string"
    $username = "clover_etl_login"
    $credential = New-Object System.Management.Automation.PSCredential $username, $securePass
    write-host "created credential"
    Import-Module SQLServer

    write-host "imported sql server module"
    Invoke-SqlCmd -Query $env:CreateMetalRole -ServerInstance localhost
    write-host "created metal role"

    Add-SqlLogin -LoginPSCredential $credential -LoginType SqlLogin -ServerInstance localhost -Enable -GrantConnectSql -DefaultDatabase master
    write-host "added login"
    $addRole = "ALTER SERVER ROLE METAL_User ADD MEMBER clover_etl_login"
    write-host "altered role"
    Invoke-SqlCmd -Query $env:ChangeLoginMode -ServerInstance localhost
    write-host "changed login mode"
    Invoke-SqlCmd -Credential $credential -Query $addRole -ServerInstance localhost
    write-host "added role"
'@

$nativeSqlCommands > createLoginSql.ps1

$processParams = @{
    "FilePath"               = "powershell"
    "Credential"             = $credential
    "RedirectStandardOutput" = "output.txt"
    "ArgumentList" = @(
        "-File",
        "./createLoginSql.ps1",
        "-Password",
        $password
    )
}

Install-Module SqlServer -Force -AllowClobber -Verbose
write-host "installed module"

[Environment]::SetEnvironmentVariable("CreateMetalRole", $createMetalRole, 'Machine')
[Environment]::SetEnvironmentVariable("ChangeLoginMode", $changeLoginMode, 'Machine')

Start-Process @processParams -Wait

# Compile and apply the AllinOne configuration
AllInOne -NewComputerName $instanceName -NrStartupType $nrStartupType -NrState $nrState -NrNetEnabled $nrNetEnabled
Start-DscConfiguration -Path .\AllInOne\ -Verbose -Wait -Force
</powershell>