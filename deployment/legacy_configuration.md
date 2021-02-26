# Legacy Configuration
*This would cover Prod US, Clover Staging (Partner), Prod Canada environments*

Clover DX servers are configured to be replaced every 30 days / build takes about 15 minutes from terraform apply to complete the necessary steps within userdata to stand up a full cloverdx server in the given environment.

Sadly some of the machines are a bit difficult to replace due to the user data that is created over the 30 days that they are in service, and many of them tend to stick around longer than they should

* I did not document which directories should be created/kept or the sets of permissions that should be in those areas

* But to facilitate of the transition of data, let’s add on a D drive to the machine so that we can replace the machine instances as necessary

To Setup the machine:

* Go to the Metal Space in Octopus
* Create a Tenant in the space if you have not already done so.
* Connect the projects to the desired space
* Currently the manual bits are …

## Manual Bits
* Install Chrome
* Install S3 Browser
* Currently: Install Security/encryption
* Copy information (sandboxes) from previous server to new server
* Switch Route53 entry to new server
### Machine Requirements
RAM start at  8 gig see how it performs (recommended 64 gig) (actual RAM is 127 Gig …)
* 16 cores
* 1 Gig of space
* 25 Gig of tempspace
* 50 gig of data space

nothing shared

#### Machine type used?

* r5a.4xlarge (vCPU was the driving factor)

#### Clustering servers?

Not applicable (staging license does not support that capability)

### Security
Minimum amount of access: 
* port 80 from client side
* port 1433 for SQL access
* port ? - RDP access

#### Users
* Current default accounts:
* fv_clover_admin
* Bill
* Susan

#### Security Groups
* Imports - Jonathan
* Migrations team access
* Import Team Users II
* Migrations team access
* Octopus
  * Octopus may need access to setup
  * This is probably overkill, and we may not want to use this …
* Dev-Wes

### Developer Access to server

#### Internal Access

Access to `import.filevinedev.com`

Had to update the security group to allow for ingress traffic from Internal Access

#### Server Configuration
Access to S3 - Filevine-devops (FIXME: currently enabled via personal access token)

All cloverdx assets should be under the directory “cloverdx-assets”

Configuration files should be stored here. Notepad seems to add additional characters and screwing up the file.

#### Apache Tomcat

Had to add application to windows firewall defender

Had to disable IIS (disabled via services panel)

Configured Tomcat to respond to Port 80

Runs as a Windows Service Service Name: “Apache Tomcat”

Current custom configuration

#### Install Microsoft SQL Server JDBC Drivers 

CloverDX Service info

New Database for cloverdx created (created in staging)

####  Created database: clover_db
#### Created clover user

Database stores all of the initial settings and what not …

SMTP server

monitoringalerts@filevine.com - gmail (see lastpass for more info)

We should use Mandrill (gmail didn’t want to work, due to a port configuration issue)

Open JDK 11

### Route 53 DNS Configuration:
* staging-cloverdx.filevinedev.com
* cloverdx.filevinedev.com
* cloverdx-ca.filevinedev.com
