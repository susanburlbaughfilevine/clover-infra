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

# Execute AllInOne Module made up of combined modules from above.
Configuration AllInOne {
    param 
    (
        [Parameter(Mandatory)]
        [string]$newcomputername
    )

    node localhost {

        InstallOctopus mytentacle
        {
            ComputerName = $newcomputername
        }
    }
}

# Begin LCM for management of reboots
LCMConfig
Set-DscLocalConfigurationManager -Path .\LCMConfig -Verbose

# Enable rebooting if needed
$global:DSCMachineStatus = 1

# Compile and apply the AllinOne configuration
AllInOne -NewComputerName $instanceName
Start-DscConfiguration -Path .\AllInOne\ -Verbose -Wait -Force
</powershell>