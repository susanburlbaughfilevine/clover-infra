<powershell>
# Start the timer
$userdata_start_time = Get-Date
Write-Output("Start Time: $userdata_start_time")

function addAdminUser
{
    param([string]$username, [string]$password, [string]$fullname, [string]$description)
    $UserPassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser $username -Password $UserPassword -FullName $fullname -Description $description
    Add-LocalGroupMember -Group 'Administrators' -Member ($username) –Verbose
}

function addNormalUser
{
    param([string]$username, [string]$password, [string]$fullname, [string]$description)
    $UserPassword = ConvertTo-SecureString $password -AsPlainText -Force
    New-LocalUser $username -Password $UserPassword -FullName $fullname -Description $description
    Add-LocalGroupMember -Group 'Users' -Member ($username) –Verbose
}

Write-Output("Start Time: $userdata_start_time / Now time: $(Get-Date)")
addAdminUser fv_clover_admin '${fv_clover_rdp_admin_password}' 'admin for clover' 'FV Clover Admin'

function addOctopusTentacle
{
    param([string]$api_key, [string]$server_address, [string]$server_environment, [string]$server_roles, [int]$listen_port, [string]$instance_name_long,  [string]$server_space, [string]$ipv4)
    ## Setup Octopus with the information captured
    $folder = "c:\dsc\config\dsc"
    Push-Location $folder

    . .\config_octopus_server.ps1 -ServerApiKey "$api_key" -ServerUrl "$server_address" -ServerEnvironments $server_environment -ServerRoles $server_roles -ServerListenPort $listen_port -serverName $instance_name_long -ServerDisplayName $instance_name_long -ServerSpace $server_space -ServerPrivateIp $ipv4
}

function getIpV4
{
    ## How do you get the Private IP that is generated from the EC2 Instance?
    ### Hit the metadata server for info
    $ipv4 = (Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/local-ipv4).Content
    # Write-Output "ipv4"
    # Write-Output $ipv4

    return $ipv4
}

Write-Output("Start Time: $userdata_start_time / Now time: $(Get-Date)")
$ip = getIpV4
addOctopusTentacle ${octopus_api_key} ${octopus_server_address} ${octopus_server_environment_metal} ${octopus_server_roles} ${octopus_listen_port} ${instance_name_long} ${octopus_server_space} $ip

addAdminUser bporter '${bporter_rdp_admin_password}' 'Bill Porter' 'Bill Porter'
addAdminUser susan '${susan_rdp_admin_password}' 'Susan' 'Susan'

</powershell>