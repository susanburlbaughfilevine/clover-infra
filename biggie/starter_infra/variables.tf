variable "region" {
  description = "Region"
  default   = "us-west-2"
}
variable "envName" {
  description = "Environment Name"
  default     = "dev"
}

variable "assume_role_arn" {
  description = "Role ARN to assume for the target of where to run this given terraform against"
}
