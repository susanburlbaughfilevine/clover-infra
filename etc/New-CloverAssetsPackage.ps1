
function New-CloverAssetsPackage
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [HashTable]$DependancyManifest
    )

    if (($null -eq $DependancyManifest) -or ($DependancyManifest.Count -lt 1))
    {
        Write-Output "No packages to download or update! Exiting."
        return $null
    }
    else
    {
        try
        {
            $packageDirectory = New-Item -Type Directory -Name clover-assets

            $DependancyManifest.GetEnumerator() | ForEach-Object -ThrottleLimit 10 -Parallel {
                $dependancy = $_
                if (($null -eq $dependancy.Value.FileLink) -or ([string]::IsNullOrEmpty($dependancy.Value.FileLink)))
                {
                    throw "Dependancy $($dependancy.Value.PackageName) was specified but no download link was provided."
                }

                if ($dependancy.Value.FileLink -eq "octopus")
                {
                    Write-Output "Package $($dependancy.Value.PackageName) is assumed to be an Octopus package. Not downloading"
                    continue
                }

                Write-Output "Downloading $($dependancy.Value.PackageName)..."

                $outputPath = Join-Path -Path $using:packageDirectory.FullName -ChildPath $dependancy.Value.PackageName

                Invoke-WebRequest -Uri $dependancy.Value.FileLink -OutFile $outputPath

                if ($dependancy.Value.Checksum -ne "none")
                {
                    $theirHash = $dependancy.Value.Checksum
                    $ourHash = (Get-FileHash -Path $outputPath -Algorithm $dependancy.Value.ChecksumType).Hash

                    if ($theirHash -ne $ourHash)
                    {
                        Write-Output "Checksum verification failure. Ours: $($ourHash) Theirs: $($theirHash)"
                        throw "Checksum verification failed for $($dependancy.Value.PackageName)!!!!"
                    }
                }
            }

            Copy-Item -Path ./octopus/package-clover-assets/PostDeploy.ps1 -Destination clover-assets/ 
            Copy-Item -Path ./config/ -Destination clover-assets/ -Recurse
            Copy-Item -Path ./etc/Install-CloverDxServer.psm1 -Destination clover-assets/
            Copy-Item -Path ./etc/Set-UserWritablePermissions.ps1 -Destination clover-assets/
            Copy-Item -Path ./etc/Wait-WorkerSqlOnline.ps1 -Destination clover-assets/
            Copy-Item -Path ./clover-assets-manifest.psd1 -Destination clover-assets/
            Compress-Archive -Path (Get-Item ".\FVBranding5.6.0\*").FullName -DestinationPath "FVBranding5.6.0.zip"
            Copy-Item -Path ./FVBranding5.6.0.zip -Destination clover-assets/
        }
        catch
        {
            Write-Output $_.Exception
            Write-Output $_.ErrorDetails
            Write-Output $_.ScriptStackTrace
        }
    }
}