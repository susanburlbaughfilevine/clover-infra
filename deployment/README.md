## Deploying Clover DX Server
All of the things are to setup Clover DX are located in the [Team Metal Octopus Work Space](https://octopus.filevinedev.com/app#/Spaces-42).



### Setting up a tenant
Go through and configure a [Tenant for the environment in the Team Metal Space](https://octopus.filevinedev.com/app#/Spaces-42/tenants)

Connect the 00 - Deploy New CloverDX Server Project and assign it to an Environment.

(There are a few untenanted environments).

### Deploying the EC2 server
* Select a [Release](https://octopus.filevinedev.com/app#/Spaces-42/projects/00-deploy-new-cloverdx-server/deployments/releases) (preferably a Master branch ...)
  * You may have to wait a few minutes for the server to deploy and report back to ScaleFT and Octopus (grab some coffee)

### After the EC2 server has been deployed
* Go through the process of the [Attached Runbooks](https://octopus.filevinedev.com/app#/Spaces-42/projects/00-deploy-new-cloverdx-server/operations/runbooks) in the project
  * Once the EC2 server has been deployed (verify by going to [infrastructure](https://octopus.filevinedev.com/app#/Spaces-42/infrastructure/machines?roles=clover-server))

#### Connecting Helper S3 bucket
* [01 - Download s3 Data to Clover system](https://octopus.filevinedev.com/app#/Spaces-42/projects/00-deploy-new-cloverdx-server/operations/runbooks/Runbooks-426/runslist)
  * You will be asked for questions around AWS credentials, Grab the credentials for the `filevine-prod` environment

#### Deploy Clover to Systems
* [02 - Deploy Clover to Systems](https://octopus.filevinedev.com/app#/Spaces-42/projects/00-deploy-new-cloverdx-server/operations/runbooks/Runbooks-427/overview)

#### Setup the Database
* Find/Setup blank database for clover to connect to (Create a RDS Server, Create MSSQL Server, etc.)
  * If this is not configured, the system will default to the blank derby database that the system will connect to. (settings will not save when system is replaced/rotated/patched.)
#### Update Clover credentials
* [03 - Update Clover Database Credentials](https://octopus.filevinedev.com/app#/Spaces-42/projects/00-deploy-new-cloverdx-server/operations/runbooks/Runbooks-428/overview)
  * This will update the clover system to point to the database that you configured in the previous step.
  * Given that the system can connect, the apache tomcat service will restart, and clover will attempt to connect to the database and setup the necessary tables, etc. so that it can start working.

#### Going to the website for the first time 
* The system will ask you for a license key, you can get this information from Susan (Team Metal)

#### Setup https
* Load Balancer and Target Groups are currently manual processes

#### Setup URL
* This is performed from the master `filevine-prod` account
  * Route 53 setup (point to the https pointer from previous step)
