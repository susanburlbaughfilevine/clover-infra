
# Install Extra Software
Write-Output "Installing Extra Software Start"
$start_time = Get-Date
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Write-Output "Install chocolatey - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "Chocolatey has been installed"
# Install Chrome
choco install GoogleChrome  -y
Write-Output "Install Google Chrome - Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
Write-Output "Google Chrome has been installed"
# chrome_installer.exe /silent /install

# Install S3 Browser

Write-Output "Installing Extra Software End"