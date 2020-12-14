<powershell>

$userdata_start_time = Get-Date

$folder = "c:\dsc\config"


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
        $NewComputerName = $env:COMPUTERNAME
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

Configuration InstallScaleFT
{
    Import-DscResource -ModuleName 'xPsDesiredStateConfiguration'
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    xRemoteFile ScaleFTDownload
    {
        Uri             = "https://dist.scaleft.com/server-tools/windows/v1.49.2/ScaleFT-Server-Tools-1.49.2.msi"
        DestinationPath = "$($env:SystemRoot)\Temp\scaleft.msi"
    }

    File ScaleFTDirectory
    {
        Type = 'Directory'
        DestinationPath = 'c:\windows\System32\config\systemprofile\AppData\Local\ScaleFT\'
        Ensure = "Present"
    }

    File ScaleFTConfig
    {
        DestinationPath = "C:\windows\System32\config\systemprofile\AppData\Local\ScaleFT\sftd.yaml"
        Ensure = "Present"
        Contents   = "${scaleft_config}"
    }

    Package ScaleFTInstall
    {
        Ensure    = "Present"
        Name      = "ScaleFT Server Tools"
        Path      = "$($env:SystemRoot)\Temp\scaleft.msi"
        DependsOn = '[xRemoteFile]ScaleFTDownload'
        Arguments = "/qn"
        ProductId = "C7306BF4-1BA4-45BF-B557-F96D793BAA00"
        ReturnCode = 0
    }
}

# Begin LCM for management of reboots
LCMConfig
Set-DscLocalConfigurationManager -Path .\LCMConfig

# Compile and apply InstallOctopus configuration
InstallOctopus -ComputerName $instanceName
Start-DscConfiguration -Path .\InstallOctopus\ -Verbose -Wait -Force

InstallScaleFT
Start-DscConfiguration -Path .\InstallScaleFT\ -Verbose -Wait -Force

# Enable rebooting if needed
$global:DSCMachineStatus = 1
# Rename the computer 
ScriptRenameComputer -NewComputerName $instanceName
Start-DscConfiguration -Path .\ScriptRenameComputer\ -Verbose -Wait -Force
</powershell>
