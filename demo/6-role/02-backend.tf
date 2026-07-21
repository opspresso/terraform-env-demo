# backend

terraform {
  required_version = "1.15.8" # terraform version

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-396608815058"
    key            = "backend/demo/role-demo/terraform.tfstate"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.55.0" # terraform aws provider version
    }
  }
}

# provider

provider "aws" {
  region = var.region
}
