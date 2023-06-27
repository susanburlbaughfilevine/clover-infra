terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    ## Remove after PagerDuty resources have been deleted (after this change has been deployed everywhere)
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "~>2.2.1"
    }
  }
  required_version = ">= 0.13"
}
