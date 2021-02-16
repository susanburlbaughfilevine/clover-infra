variable "envName" {
  description = "Environment Name"
  default     = "dev"
}

variable "assume_role_arn" {
  description = "Role ARN to assume for the target of where to run this given terraform against"
}

variable "dns_domain" {
  description = "dns domain this environment is setup against - ie. filevinedev.com"
  default     = "filevinedev.com"
}

variable "subdomain" {
  description = "subdomain this environment is setup against - ie. teamqa-lego"
  default     = "notset-demo"
}

# Node.js Variables for Slack Alert Lambda Function
variable "slack_channel_name" {
  description = "Slack channel name to push Lambda sourced SNS notifications"
}

variable "slack_webhook" {
  description = "Webhook for the Slack channel above"
}
