# CloverDX

## What is CloverDX?
CloverDX is a data migration software that allows us to migrate different types of databases into data that our system can read.

## What are the moving parts of CloverDX?
* Apache Tomcat (Java web app container) (v 9.3.0+)
* OpenJDK JRE 11
* CloverDX (Data Migration Software)
* CloverDX Data Profiler
* MSSQL Connection Libraries
* Encryption: Bouncy Castle (Java)
* Amazon Cloudwatch
* [TODO] Clover App Branding (for filevine branding)

## Where do server build assets live? (tomcat, jre, etc.)
There is an S3 bucket for the filevine-devops group, and we have a directory for the cloverdx server there.

As part of the build process, we reach out and grab that s3 bucket directory and put that into a local working directory of "C:\clover_assets"

## Installing CloverDX
* [Local Development](./LOCAL.md)
* [Deployment Instructions](./deployment/README.md)
* [After Server Setup](./deployment/after_server_setup.md)

### Things to do (Cleanup)
* move start_infra flow into the TF Stack (design discussion)
### Other Notes (CJIS Specific)
* [Secure Tunnel to CJIS Import Tools](https://filevine.atlassian.net/wiki/spaces/DEVOPS/pages/1134362629/Secure+Tunnel+to+CJIS+Import+Tools)
#### Copy <5G files around
To move all <5G files around.
1. Created an AWS S3 Inventory of the Million+ files folder into a CSV format.  
1. Downloaded the CSV to my machine
1. Ran powershell to suck the CSV into memory (not very memory efficient) with `$rawdata= get-content filename; $data = $rawdata | Import-CSV -headers 'bunch o headers listed here'; Split into two object with a for each loop comparing size.   Then export-csv out without the header line using just bucket,keyname attributes.  
1. Using the two CSVs (limit on <5G files) I did an S3 Batch Copy Operation to move about 22TB in about 2.5 hours in the destination account.

The >5G files Austin has been fighting with for the last 3 days.

* [S3 Batch Operations - AWS](https://aws.amazon.com/blogs/storage/cross-account-bulk-transfer-of-files-using-amazon-s3-batch-operations/)
* [Inventory](https://docs.aws.amazon.com/AmazonS3/latest/userguide/storage-inventory-location.html)