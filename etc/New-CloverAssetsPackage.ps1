function New-CloverAssetsPackage
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [HashTable]$DependancyManifest
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (($null -eq $DependancyManifest) -or ($DependancyManifest.Count -lt 1))
    {
        Write-Output "No packages to download or update! Exiting."
        return $null
    }
    else
    {
        $c = New-Object System.Net.WebClient

        $packageDirectory = New-Item -Type Directory -Name clover-assets

        foreach ($dependancy in $DependancyManifest.GetEnumerator())
        {

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

            $outputPath = Join-Path -Path $packageDirectory.FullName -ChildPath $dependancy.Value.PackageName

            $c.DownloadFile($dependancy.Value.FileLink, $outputPath)

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
        Compress-Archive -Path $packageDirectory.FullName -DestinationPath clover-assets.zip -Verbose
    }
}