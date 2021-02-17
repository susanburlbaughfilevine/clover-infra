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
    terraform apply -input=false testfile
}

task set_provider {
    # set the provider info file (generate that dynamically)
    . .\setProviderTf.ps1 # 
}

task destroy_environment {
    terraform destroy -input=false -var-file local_vars.tfvars
}


task destroy destroy_environment
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

task rebase_continue {
  git rebase --continue
}

task rebase_skip {
  git rebase --skip
}
