terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  
  required_version = ">= 0.13"

  cloud {
    organization = "Postech-YJ"

    workspaces {
      name = "aws-lambda"
    }
  }
}

provider "aws" {
  region = var.regionDefault
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}