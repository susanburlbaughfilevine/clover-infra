task parent-test init, validate, plan

task init {
    terraform init
}

task validate {
    terraform validate
}

task plan {
    terraform plan  -var-file local_vars.tfvars --out=testfile -input=false
}

task apply {
    terraform apply -var-file local_vars.tfvars -input=false testfile
}

# We do not want to store information like passwords, etc.
# in the code, so we set those via variables. We can set
# via environment variables. So that the operations people
# can have better control over these settings.
task set_environment_variables {
    # If there is a file here (.env), use those settings (how do we read those?)
    # $setEnv = Read-Host -Prompt 'Set Environment Script [setEnv.ps1]'
    . .\setEnv.ps1 # $setEnv
    # Get-Item -Path Env:* | Get-Member
}

#task set_environment_variables_canada {
#    # If there is a file here (.env), use those settings (how do we read those?)
#    # $setEnv = Read-Host -Prompt 'Set Environment Script [setEnv.ps1]'
#    . .\setEnv-canada.ps1 # $setEnv
#    # Get-Item -Path Env:* | Get-Member
#}

task plan_production {
    terraform plan -var-file clover_us.tfvars -out=testfile -input=false
}

task set_environment_variables_staging {
    . .\setEnv_staging.ps1 # $setEnv

}

task plan_staging {
    terraform plan -var-file clover_staging.tfvars -out=testfile -input=false
}

task set_environment_variables_canada {
    # If there is a file here (.env), use those settings (how do we read those?)
    # $setEnv = Read-Host -Prompt 'Set Environment Script [setEnv.ps1]'
    . .\setEnv-canada.ps1 # $setEnv
    # Get-Item -Path Env:* | Get-Member
}


task plan_canada {
    terraform plan -var-file clover_canada.tfvars -out=testfile -input=false
}

task set_provider {
    # set the provider info file (generate that dynamically)
    . .\setProviderTf.ps1 # 
}


task destroy_environment {
    terraform destroy -input=false
}

task reset_environment destroy_environment,parent-test,apply

task set_local {
  remove-item provider.tf
  copy-item -Force provider.tf_local provider.tf
  cat provider.tf
}

task set_octopus {
  remove-item provider.tf
  copy-item -Force provider.tf_octopus provider.tf
  cat provider.tf
}

task save_local {
  copy-item -Force provider.tf provider.tf_local
}

task save_octopus {
  copy-item -Force provider.tf provider.tf_octopus
}

