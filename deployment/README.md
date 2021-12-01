# How to Deploy?
* This is set up to be as modular as possible so that we can deploy bits and pieces as necessary (in the event that we need to deploy clover to a separate server on it's own ...)
## Gitlab
Gitlab will automatically build deploy packages and push those to octopus as necessary.

## Deploying Clover DX Server
All of the things are to setup Clover DX are located in the [MigrateTech-CloverDX Work Space](https://octopus.filevinedev.com/app#/Spaces-243).

### Setting up a tenant
Go through and configure a [Tenant for the environment in the MigrateTech-CloverDX Space](https://octopus.filevinedev.com/app#/Spaces-243/tenants)

Connect the 00 - Deploy New CloverDX Server Project and assign it to an Environment.

(There are a few untenanted environments).

### Deploying the EC2 server
* Select a [Release](https://octopus.filevinedev.com/app#/Spaces-243/projects/00-deploy-new-cloverdx-server/deployments/releases) (preferably a Master branch ...)
  * You may have to wait a few minutes for the server to deploy and report back to ScaleFT and Octopus (grab some coffee)

The ec2 server that we pull is the standard EC2 (AMI) instance we use for our other servers.

By default the IIS web server will be available and running when we first boot up the system.

#### Setup the Database
* **Note** The clover database may need to be on the same server as the Filevine_META database ...

##### First time setup
* Find/Setup blank database for clover to connect to (Create a RDS Server, Create MSSQL Server, etc.)
  * If this is not configured, the system will default to the blank derby database that the system will connect to. (settings will not save when system is replaced/rotated/patched.)

By storing the clover_db on a RDS, it would allow you to carry over the data from the previous build, and it would allow you to rebuild the server, and the credentials. 

An alternative approach is if we have to store data on a ec2 system, we want to have a spare drive available so that we can store the database (the actual database, not the SQL server) on the spare drive.

###### SQL Server Setup
```
CREATE DATABASE <CLOVER_DB>;
ALTER DATABASE <CLOVER_DB> SET READ_COMMITTED_SNAPSHOT ON;
CREATE LOGIN <CLOVER_USER> WITH PASSWORD = '<CLOVER_PASSWORD>', DEFAULT_DATABASE = <CLOVER_DB>;
USE <CLOVER_DB>;
CREATE USER <CLOVER_USER> FOR LOGIN <CLOVER_USER>;
EXEC sp_addrolemember 'db_owner', 'clover';
```
* Cannot set default database to database due to multi-az ... (commented that part out, hopefully it won't cause issues.)

**Notes**
* RDS does not have sysadmin capabilities

##### CJIS Configuration
* [Setup RDS Instance](https://octopus.filevinedev.com/app#/Spaces-243/projects/00-deploy-new-cloverdx-server/operations/runbooks/Runbooks-506/overview)

Some of the settings are currently hardcoded for CJIS.

### After the EC2 server has been deployed
* Go through the process of the [Attached Runbooks](https://octopus.filevinedev.com/app#/Spaces-243/projects/00-deploy-new-cloverdx-server/operations/runbooks) in the project
  * Once the EC2 server has been deployed (verify by going to [infrastructure](https://octopus.filevinedev.com/app#/Spaces-243/infrastructure/machines?roles=clover-server)) - Click refresh until you see the clover deployed for your tenant.

Now that the server has been deployed, and is reachable by octopus, we can begin the next steps in the process.
#### Connecting Helper S3 bucket
* [01 - Download s3 Data to Clover system](https://octopus.filevinedev.com/app#/Spaces-243/projects/00-deploy-new-cloverdx-server/operations/runbooks/Runbooks-426/runslist)
  * You will be asked for questions around AWS credentials, Grab the credentials for the `filevine-prod` environment.
  * You may use the Monitoring Access Credentials.

We are using this method of getting data onto the server, mostly because this will allow us to pull data from a different aws account, and pull that information into the EC2 Instance.

#### Deploy Clover to Systems
* [02 - Deploy Clover to Systems](https://octopus.filevinedev.com/app#/Spaces-243/projects/00-deploy-new-cloverdx-server/operations/runbooks/Runbooks-427/overview)
  * Clover will run the port 80, and sometimes has issues shutting down IIS properly
  * In other words, you may need to disable the IIS server manually
    * Set IIS to disabled / so that it no longer starts on startup
  * Double check that the Tomcat service is set to Automatically start on startup
  * If you have already configured a database for this system, the credentials will populate during this step.

This is actually the entire script that will do the following
* Install Tomcat
* Install JDK
  * Set Environment Variables
* Set Provider and Clover Server Properties - Database Credentials
* Update Permissions for properties files to allow the clover server ability to save from web interface
* Copy JDBC drivers to class library path
* Install Bouncy Castle Encryption
* Install secure Config Tool
* Use specific server.xml files
* Stop/Disable IIS
* Install/Start Tomcat Service
* Update Firewall Rules

#### Update Clover credentials
* In the event that you did not have the correct credentials populated in octopus, you may update the credentials using this step.
* [03 - Update Clover Database Credentials](https://octopus.filevinedev.com/app#/Spaces-243/projects/00-deploy-new-cloverdx-server/operations/runbooks/Runbooks-428/overview)
  * This will update the clover system to point to the database that you configured in the previous step.

#### Going to the website for the first time 
* The system will ask you for a license key, you can get this information from Susan Burlbaugh (Team Metal)

##### Initial Startup
* username: clover
* password: clover

You will also be asked for a license key. These license keys should be available via the [cloverdx website](https://support.cloverdx.com/license-keys). If you do not access to these, you may need to check with Susan or Abby (these should be already configured) ...

You will need to set up the database connection to the central server where cloverdx stores it's info. the system can connect, the apache tomcat service will restart, and clover will attempt to connect to the database and setup the necessary tables, etc. so that it can start working.

#### Setup https
* Load Balancer and Target Groups are currently manual processes
* This may have been setup as part of the CJIS configuration, we may need to investigate how to pull that into the main code.

#### Setup URL
* This is performed from the master `filevine-prod` account
  * Route 53 setup (point to the https pointer from previous step)

**Clover URL:** `clover-${envName}.filevine.com` (some form of ...)
* This should point to the Load Balancer that points to the Target Group that points to this ec2 instance
  * This method was used so that we could enable https

##### Other URLs that should exist
* Some form of `internal-${envName}-import.filevine.com`
  * This points to the same server that the migration team is working from.
  * Should refer to the private IP address.
  * This should be an A Name record (since this would be pointed to an EC2 server - import server is typically an EC2 server)

### Server is setup
At this point, the server is setup, there are a few manual steps.

Please see the next step in the instructions - [After Server Setup](./after_server_setup.md)


---
#### Previous Configuration Instructions
##### Octopus
* This work was already performed:
  * Canada Servers must be manually added to the [Octopus Security Group](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#SecurityGroups:group-id=sg-16534673;sort=tag:Name)

### Build and Release process
* Currently main assets are stored on S3 (filevine_devops/cloverdx_assets)
* Everything else is pulled in via environment variables (set via script)
* Currently route53 address is assigned to static IP addresses (we have to adjust it manually)

## Manual / Clover installation (Stand alone)
There shouldn't be too many situations where you need to stand up a clover installation outside of the already existing
systems, but if the situation arises, please review:
* [Post installation documentation](https://doc.cloverdx.com/latest/server/postinstallation-configuration.html)

See the "SQL Server Setup" for additional setup/instructions


#### Manual Steps as part of automation steps / Deployment
* [TODO] Update data steps with Links
* verify octopus tentacle connection
   * Space: Metal
   * Tag: clover-server
* Execute commands from [Octopus Runbook](https://octopus.filevinedev.com/app#/Spaces-243/projects/01-runbook-cloverdx-server/operations/runbooks)
   * Download Assets from S3 (you'll need to grab temporary keys)
   * Install Clover - Push button
   * Install Extra Software (Manual Process?)
      * via scoop?
      * S3 Browser
      * Chrome
        * There is a DSC available for this (maybe?)
      * Notepad++
      * sysinternals
   * Push Files from Previous System (not working) - Manual Process / Not planned out
   * Update Clover Database Credentials (Part of Runbook)
   * Apply Branding (part of runbook)
   * Restart Tomcat (part of runbook)
   * Display Current Cloudwatch Configuration (part of runbook) - By default the cloudwatch reporting metrics are less than useful, this will allow us to confirm what metrics are available on the system. - I have not checked how this compares against latest IAM profile cloudwatch settings ... (use at your own risk ...)
   * Update Cloudwatch on Server (part of runbook) - There are customized cloudwatch configs for this system, and runbook should allow you to see additonal values about the system. () 
   * Stop Cloudwatch Agent (part of runbook) - Stop the windows service
   * Start Cloudwatch Agent (part of runbook) - Start the windows service
