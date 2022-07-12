terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~>2.37.0"
    }

    ## Remove after PagerDuty resources have been deleted (after this change has been deployed everywhere)
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "~>2.2.1"
    }
  }
  required_version = ">= 0.13"
}