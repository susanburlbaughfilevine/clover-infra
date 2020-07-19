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
* [WAIT] Clover App Branding (for filevine branding)

## Where do server build assets live? (tomcat, jre, etc.)
There is an S3 bucket for the filevine-devops group, and we have a directory for the cloverdx server there.

As part of the build process, we reach out and grab that s3 bucket directory and put that into a local working directory of "C:\clover_assets"

## Installing CloverDX
### Where do I get the License Key
License keys are tied to user accounts, ask Abby Malson or Susan for access to this info if needed

### Default Credentials
Username: clover
Password: clover

**NOTE:** If deployed to preexisting environment (production, production canada, etc.), default credentials may not work (because it would connect to the already existing database with existing credentials)

## How to Deploy?
### Gitlab (New Process)
Gitlab now auto builds clover packages into octopus.

It will be available as a release option within octopus. (displaying information as semver)


Teamcity is not set to auto build updates to the repository

### TeamCity
* Go to the ["Metal" Project in teamcity](https://teamcity.filevinedev.com/project/Metal?branch=&mode=builds#all-projects)
* Go to Project ["Clover"](https://teamcity.filevinedev.com/buildConfiguration/Metal_Clover?branch=&mode=builds)
* Find the specific branch you wish to deploy (release or master)
* Teamcity will generate a release number (incremented from the previous release)
* Use the generated release number to find the associated release in Octopus

#### Why doesn't my branch appear in the list of builds?
* Branches that match "(release/*)" or **master** will build

### Octopus
Octopus is not set to auto deploy new releases
* Go to the ["Metal" Space in Octopus (Space-42)](https://octopus.filevinedev.com/app#/Spaces-42)
* Go to Project ["00 - Deploy New CloverDX Server"](https://octopus.filevinedev.com/app#/Spaces-42/projects/00-deploy-new-cloverdx-server/deployments)

### Manually
If for some reason you would like to test things locally
* Verify that the necessary environment variables are set
* Create a `.tfvars` file that specifies the appropriate values for your deploy
* Update Makefile.build.ps1 to include your new `.tfvars` file
* terraform init
* terraform plan
   * `terraform plan -var-file MY_NEW_TFVAR_FILE.tfvars -out=testfile -input=false`
* terraform apply

### If you're cleaning up after a test:
* terraform destroy

### To reset the environment (since we're in a testing state)
Invoke-Build reset_environment

### How do I know if I'm in a testing state?
Check the provider.tf - make sure that you are using a "non-production" terraform key
(line 12)

#### What do you mean "non-production" terraform key?
* Is the current setting already getting traffic from outside users? 
## Pre-Requisites
Climb onto database, and create a clover database and user so that it can store whatever it needs to on the server (graphs, data cache, etc.).

I say this is a prerequisite since the license key info is stored in the database
### Protip: don't have `$` in your password, it messes with the automation

### Environment Variables
* See setEnv_template.ps1

## Initial Startup
* username: clover
* password: clover

You will also be asked for a license key. These license keys should be available via the [cloverdx website](https://support.cloverdx.com/license-keys). If you do not access to these, you may need to check with Susan or Abby (these should be already configured) ...

You will need to set up the database connection to the central server where cloverdx stores it's info.

## Post Installation
[Post installation documentation](https://doc.cloverdx.com/latest/server/postinstallation-configuration.html)

### Mail server notes
* Gmail does not seem to allow for connection through smtp (I try, I get an error)
* Find out what kind of mail it would send out?

### Logging
* We send our logs to cloudwatch (is the default answer) - Cloudwatch has it's own log analysis capabilities ...
* This will get us by until we start the cloudwatch stuff (custom installation of things would require someone to run the cloudwatch configuration process)

### SQL Server Setup
```
CREATE DATABASE <CLOVER_DB>;
ALTER DATABASE <CLOVER_DB> SET READ_COMMITTED_SNAPSHOT ON;
CREATE LOGIN <CLOVER_USER> WITH PASSWORD = '<CLOVER_PASSWORD>', DEFAULT_DATABASE = <CLOVER_DB>;
USE <CLOVER_DB>;
CREATE USER <CLOVER_USER> FOR LOGIN <CLOVER_USER>;
EXEC sp_addrolemember 'db_owner', 'clover';
```
* Cannot set default database to database due to multi-az ... (commented that part out, hopefully it won't cause issues.)

### Build and Release process
* Currently main assets are stored on S3 (filevine_devops/cloverdx_assets)
* Everything else is pulled in via environment variables (set via script)
* Currently route53 address is assigned to static IP addresses (we have to adjust it manually)

## Manual / Clover installation (Stand alone)
There shouldn't be too many situations where you need to stand up a clover installation outside of the already existing
systems, but if the situation arises, please review:
* [Post installation documentation](https://doc.cloverdx.com/latest/server/postinstallation-configuration.html)

See the "SQL Server Setup" for additional setup/instructions

## FAQ
### I need to update the default password that will be used on new systems
Since everything is configured via Octopus, the best place to update that information is in Octopus Variables for the project
