## Post Installation
Now that you have everything installed, there are a few more things that we need to do to clean things up.

[Post installation documentation](https://doc.cloverdx.com/latest/server/postinstallation-configuration.html)

### Turn on Encryption
* Encryption is an additional setting in the admin area (you want to use the bouncy castle) (should have been installed via initial setup)
* Set Master Password

### Mail server notes
* we can probably set this up to use the mail servers in Filevine ... (isn't there a SMTP system we can connect to?)
  * Mandrill?
* Gmail does not seem to allow for connection through smtp (I try, I get an error)
* Find out what kind of mail it would send out?

### Logging
* We send our logs to cloudwatch (is the default answer) - Cloudwatch has it's own log analysis capabilities ...
* This will get us by until we start the cloudwatch stuff (custom installation of things would require someone to run the cloudwatch configuration process)

### Where do I go to look for logs?
* C:\tomcat\v9\apache-tomcat\temp\cloverlogs
* $TOMCAT_HOME\temp\logs

### Configure Aliases (CJIS Specific)
* sft alias
  * Setup sftd.yaml
```yml
bastion: filevine-bastion-cjis
altNames: ["fv-cjis-tools", "dm-cjis-tools"]
```
behavior tries the bastion name listed, if there is more than one instance with the same name, it randomly selects it.

Altnames allow us to to support the previous names until we get the pipelines working well.

* DNS alias
  * Configure A Record to point to `dm-cjis-tools.filevinedev.com`

### Configure Backend Security Group (CJIS Specific)
* Added `172.17.80.0/21` to the incoming port 1433 in the background SG (this may be done in code)

### Create S3 Bucket for Clover

### Update Service Account AWS Credentials for Clover (s3 access)

### Setup Credentials for the Filevine_Meta Database

### Installing DocScan
* Go to DocScan Repo, download contents (zip of repo)
* Unzip Archive
* Zip up the directory underneath the parent directory, so that everything is on the root of the zip file.
* Upload the new zip file through Clover Interface into the Sandboxes
  * Click on New Sandbox
    * Sandbox Configuration (final settings in CJIS)
```xml
<?xml version='1.0' encoding='UTF-8'?>
<cs:cloverServerConfiguration xmlns:cs="http://cloveretl.com/server/data" cloverVersion="5.6.0.18" exporter="clover" timeZone="UTC" timestamp="2021-02-25T20:54:07.185Z">
  <cs:usersList/>
  <cs:userGroupsList/>
  <cs:sandboxesList>
    <cs:sandbox>
      <cs:id>0</cs:id>
      <cs:ownerUsername>clover</cs:ownerUsername>
      <cs:distributionType>shared</cs:distributionType>
      <cs:sandboxPermissions>
        <cs:permission>
          <cs:userGroupCode>ExecutionLogView</cs:userGroupCode>
          <cs:operation>read</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>ExecutionLogView</cs:userGroupCode>
          <cs:operation>write</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>ExecutionLogView</cs:userGroupCode>
          <cs:operation>execute</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>ExecutionLogView</cs:userGroupCode>
          <cs:operation>viewResults</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>ExecutionLogView</cs:userGroupCode>
          <cs:operation>cleanResults</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>all_users</cs:userGroupCode>
          <cs:operation>read</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>all_users</cs:userGroupCode>
          <cs:operation>write</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>all_users</cs:userGroupCode>
          <cs:operation>execute</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>all_users</cs:userGroupCode>
          <cs:operation>viewResults</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>all_users</cs:userGroupCode>
          <cs:operation>cleanResults</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>execute_data_service</cs:userGroupCode>
          <cs:operation>read</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>execute_data_service</cs:userGroupCode>
          <cs:operation>write</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>execute_data_service</cs:userGroupCode>
          <cs:operation>execute</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>execute_data_service</cs:userGroupCode>
          <cs:operation>viewResults</cs:operation>
        </cs:permission>
        <cs:permission>
          <cs:userGroupCode>execute_data_service</cs:userGroupCode>
          <cs:operation>cleanResults</cs:operation>
        </cs:permission>
      </cs:sandboxPermissions>
    </cs:sandbox>
  </cs:sandboxesList>
  <cs:jobConfigsList/>
  <cs:schedulesList>
    <cs:schedule enabled="true">
      <cs:id>3</cs:id>
      <cs:description>dataloader cjis</cs:description>
      <cs:ownerUsername>clover</cs:ownerUsername>
      <cs:startTime>2021-02-25T20:04:10.760Z</cs:startTime>
      <cs:intervalPeriodicity>true</cs:intervalPeriodicity>
      <cs:interval>5</cs:interval>
      <cs:intervalUnit>MINUTES</cs:intervalUnit>
      <cs:onetime>false</cs:onetime>
      <cs:cronExpression>0 0 1 * * ?</cs:cronExpression>
      <cs:fireMisfired>true</cs:fireMisfired>
      <cs:task xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="cs:taskExecuteJobflow" taskType="execute_jobflow">
        <cs:jobFile>jobflow/loader/loadByProcessingGroupID.jbf</cs:jobFile>
        <cs:sandboxCode></cs:sandboxCode>
        <cs:saveRunRecord>true</cs:saveRunRecord>
      </cs:task>
    </cs:schedule>
  </cs:schedulesList>
  <cs:eventListenersList/>
  <cs:launchServicesList/>
  <cs:dataServicesList/>
  <cs:tempSpacesList/>
</cs:cloverServerConfiguration>
```
  * Open `parameters.prm` file
    * Secret key, etc. go on Line 6
    * Setting `secure="true"` will cause the value to appear as `*`s
    * Update aws credentials
      * Currently we use AWS Secret key and Access Keys since this user in clover may not have a connection to the S3 bucket, and may not have access to the Server's credentials that are baked into the instance profile (waiting to evaluate)
        * clover performs ssh calls to s3
        * clover uses clover_etl_login to access aws (clover_etl_login may be a windows user)
    * ImportServer = value that should be updated (point to the appropriate server url address)
    * Change the `case` statement value to all lowercase

### Access the Import Server Database (We need to create assets)
* Create server login `clover_etl_login` in Filevine Import Database
    * Check Server Roles
      * METAL_User
    * Map to Database
      * Filevine_Meta
    * Go into Filevine_Meta
      * execute dbo.usp.createserverroles
        * Return value should be 0

### Install JTDS
Docscan code uses JTDS (SQL Server Open Source Driver) - Download link is via [Sourceforge](https://sourceforge.net/projects/jtds/files/jtds/)
* [Clover MSSQL Authentication](https://doc.cloverdx.com/latest/designer/mssql-authentication.html)
* The dll file should be placed in a windows system path
* Code may already be on the server?
#### CJIS Specific
* We ended up install the JTDS dll file in the `C:\Windows\System32` directory
* code line added to the top of the `catalina.bat` file

### Confirming Docscan is Functional
* Run the sandbox test
* Check for a S3DocScan table in the Import Database
  * `select * from S3DocScan`

## FAQ
### I need to update the default password that will be used on new systems
Since everything is configured via Octopus, the best place to update that information is in Octopus Variables for the project

### Clover is Installed, Now What?
* DocscanCJIS does not house aws key, Connection Password

### Evaluating connections
* `test-netconnection -computername IP_ADDRESS -PORT 1433`

### Potential points of failure
* FV Branding may not be accessible - Check the Clover logs
  * FV Branding should be placed in the `C:\tomcat\` directory
* ImportServer URL may not be getting replaced properly within the code.
* SSPI - JTDS Library is not loading correctly
  * Download and install the drivers
  * [Clover MSSQL Authentication](https://doc.cloverdx.com/latest/designer/mssql-authentication.html)
* Worker failed to start?
  * Double check the URL that the “/clover” is present
  * If not, chances you are on older version of the machine image, and need to start the service via command line:
  * PS C:\tomcat\CloverDXServer.5.5.1.Tomcat-9.0.22\bin> `.\startup.bat`
    * This should be resolved once we can rotate the servers (and figure out the hard drive rotation plan/strategy)
* Setting Worker Class Path 
  * the CloverDX server has two parts, Core and Worker. 
  * Tasks are usually run in the Worker so you need to add this library to `worker.classpath`. 
  * [Adding Libraries to Worker Classpath](https://doc.cloverdx.com/latest/server/optional-server-installation-steps.html#adding-libraries-to-worker-classpath).
    * Make sure the `worker-lib` directory is created in CloverDX home directory 
    * add `worker.classpath` property into CloverDX configuration file (Configuration/Setup/Configuration File)
    * Restart CloverDX server.
