# Local Deployment/Development
Sometimes developing working on terraform can be a bit difficult, so we built out some functions to help make things easier.

## Check the provider.tf
You may want to verify that you are using the correct configuration.

The basic method of verifying is looking for the octopus provider information.

* `cat provider.tf`

## Requirements
Please set the AWS credentials for the environment you wish to deploy.

## Using Invoke-Build
Available Commands
* `Invoke-Build save-octopus` - Saves current provider.tf to provider.tf_octopus
* `Invoke-Build save-local` - Saves current provider.tf to provider.tf_local
* `Invoke-Build set-octopus` - Replaces provider.tf with provider.tf_octopus 
* `Invoke-Build set-local` - Replaces provider.tf with provider.tf_local 
* `Invoke-Build init` - Executes `terraform init`
* `Invoke-Build validate` - Executes `terraform validate`
* `Invoke-Build plan` - Executes `terraform plan -var-file local.tfvars`
* `Invoke-Build apply` - Executes `terraform apply`
* `Invoke-Build validate` - Executes `terraform validate`
* `Invoke-Build destroy` - Executes `terraform destroy`


(Just in case you can't do octopus options/can't build on your own)

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

