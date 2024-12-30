# backend

terraform {
  required_version = "1.7.5" # terraform version

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-396608815058"
    key            = "backend/demo/role-demo/terraform.tfstate"
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0" # terraform aws provider version
    }
  }
}

# provider

provider "aws" {
  region = var.region
}
