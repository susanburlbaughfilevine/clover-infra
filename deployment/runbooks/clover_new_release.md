# Clover released a new version
## Access Clover website
* https://support.cloverdx.com/downloads
* Download the cloverdx, all in one setup
* Upload that file to the `filevine_prod` -> `filevine_devops` bucket
* Update the file pointer value in the [Deploy project](https://octopus.filevinedev.com/app#/Spaces-42/projects/00-deploy-new-cloverdx-server/variables)

**Deprecated Instructions**
* Unzip that, and place the contents of the “webapps/” in the s3 bucket https://s3.console.aws.amazon.com/s3/buckets/filevine-devops/cloverdx-assets/?region=us-west-2&tab=overview
* clover.war
* profiler.war

## Grab the zip file as well, and upload all of the contents to the s3 buckets

## Build servers