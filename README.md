# Clover DX Server Application &  Infrastructure
This repository is home to the infrastructure used to support the CloverDX server application, and the processes used to deploy it.

Below you'll find answers to what are assumed to be common questions regarding deploying this project and maintaining it.

### I need to deploy a release of CloverDX server and its supporting infrastructure to an existing environment.
- Navigate to the Octopus Deploy project [Deploy CloverDX Server - Windows](https://octopus.filevinedev.com/app#/Spaces-243/projects/deploy-cloverdx-server-windows/deployments). Select a release and deploy to the environment of your choice.

### I need to deploy CloverDX server and its supporting infrastructure to a new environment.
- Create a new Octopus tenant in the [MigrateTech-CloverDX](https://octopus.filevinedev.com/app#/Spaces-243/tenants) space.
- Connect the `Deploy CloverDX Assets - Windows` and `Deploy CloverDX Server - Windows` projects to your new tenant.
- Update the variables for your new Octopus Tenant in the Teants menu.
- Deploy a release of `Deploy CloverDX Server - Windows` to your tenant


### A new version of CloverDX Server (or any of its dependancies) is available. How can I get things updated?
* The file [clover-assets-manifest.psd1](clover-assets-manifest.psd1) contains a list of software required to run the  CloverDX server application (including CloverDX itself). Each item in the list contains the following:
    - **PackageName** (Required): The PackageName is the resultant name of the file after it is downloaded and (if neccessary) unpacked from its ZIP archive
    - **FileLink** (Required): The URL from which the CI pipeline will fetch the file.
    - **Version** (Optional): The version of the package to be downloaded
    - **Checksum** (Optional): The checksum provided by the package developer. If this value is populated, a checksum verification will be run against the package based on the algorithim specified in the `ChecksumType` property.
    - **ChecksumType**: (Optional -> Required if `Checksum` is set): The algorithim that will be used to run a checksum verification against the downloaded package. Valid options enumerated [here](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-filehash?view=powershell-5.1#parameters).


    In order to update the version of CloverDX or any of its dependancies, update the manifest file with the appropriate information pertaining to the software version. For example, to update Apache Tomcat from version 9.0.56 to 9.0.58, the following changes would need to be made to `clover-assets-manifest.psd1`:
    
    ```
    # Old Apache Tomcat - Version 9.0.56
        tomcat = @{
            PackageName      = "apache-tomcat-9.0.56.zip"
            FileLink         = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.56/bin/apache-tomcat-9.0.56-windows-x64.zip"
            Version          = "9.0.56"
            Checksum         = "63a73d6370920bb7ac383f38f10f66a437dc066d72c59075091a86711c604d0f0ffd917379251a0a5d3caafee3c4e15e21643194d4fb887722920c7afbec23ad"
            ChecksumType     = "sha512"
        }

    # New Apache Tomcat - Version 9.0.58. This will replace the old version definition above ^
        tomcat = @{
            PackageName      = "apache-tomcat-9.0.58.zip"
            FileLink         = "https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.58/bin/apache-tomcat-9.0.58-windows-x64.zip"
            Version          = "9.0.58"
            Checksum         = "e2e70436cb29de2a53c2ce6bf1232dc7fb280aea57359f5d1b337569aa860ac6339e9ea847d597e9cfd93240e2daa36329c66e65f024129da9f67b1b6c24bf39"
            ChecksumType     = "sha512"
        }
    ```

    During the next run of the CI pipeline build step, the new version will be pulled and packaged with the clover-assets bundle that will be pushed to Octopus Deploy. 