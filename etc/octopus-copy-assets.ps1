# Used by Octopus project "Deploy CloverDX Assets - Windows" to deploy assets to CloverDX server
dir
Expand-Archive -Path cloverdx-windows\clover-assets.zip -DestinationPath $env:SYSTEMDRIVE\ -Force