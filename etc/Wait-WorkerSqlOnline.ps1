param(
    [string]$WorkerIp,
    [int]$timeout = 35
)

Write-Host "WorkerIP : $WorkerIp"
$WorkerIp | gm
$WorkerIp.value

Write-Host "Waiting for SQL Server on the worker to come online. If this is the first deploy, this can take up to 30 minutes"

$sqlNotOnline = $true

$stopTime = ([datetime]::now).AddMinutes($timeout)

while ($sqlNotOnline) {
    $checkParams = @{
        "ComputerName"     = $WorkerIp
        "InformationLevel" = "Quiet"
        "Port"             = 1433
    }

    $result = Test-NetConnection @checkParams

    if ($result) {
        Test-NetConnection @checkParams
        $sqlNotOnline = $false
        break
    }

    if ([datetime]::now -gt $stopTime) {
        throw "Timeout reached! Could not connect to MSSQL at $($WorkerIp)"
    }
}