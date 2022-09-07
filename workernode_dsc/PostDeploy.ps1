Install-Module xPsDesiredStateConfiguration -Verbose
Install-Module NetworkingDsc -Verbose
Install-Module SqlServerDsc -Verbose
Install-Module cChoco -Verbose

$cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256
$cert | Export-Certificate -FilePath "C:\dsc\DscPublicKey.cer" -Force
$thumbprint = $cert.Thumbprint
Import-Certificate -FilePath "c:\dsc\DscPublicKey.cer" -CertStoreLocation Cert:\LocalMachine\My

[DSCLocalConfigurationManager()]
configuration LCMConfig
{
  Node "localhost"
  {
    Settings
    {
      RebootNodeIfNeeded = $True
      CertificateID = $thumbprint
    }
  }
}

LCMConfig

Set-DscLocalConfigurationManager -Path .\LCMConfig

$global:DSCMachineStatus = 1

. ./WorkerNode_DSC.ps1

$ConfigData = @{
  AllNodes = @(
      @{
          # The name of the node we are describing
          NodeName        = "localhost"
          CertificateFile = "C:\dsc\DscPublicKey.cer"
          # The thumbprint of the Encryption Certificate
          # used to decrypt the credentials on target node
          Thumbprint      = $thumbprint
      }
  )
}

WorkerNode -InstallUser "clover_etl_login" -ConfigurationData $ConfigData

Start-DSCConfiguration ./workernode -wait -force 