terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.9.0, < 5.0.0"
    }
  }
  required_version = ">= 1.1"
}
