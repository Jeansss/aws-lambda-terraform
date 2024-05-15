terraform {
  required_providers {
    mongodbatlas = {
      source = "mongodb/mongodbatlas"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
  
  required_version = ">= 0.13"

  cloud {
    organization = "Postech-YJ"

    workspaces {
      name = "amazon-eks"
    }
  }
}

provider "aws" {
  region = var.regionDefault
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
}