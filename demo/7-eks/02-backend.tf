# backend

terraform {
  required_version = "1.7.5" # terraform version

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-396608815058"
    key            = "backend/demo/eks-demo/terraform.tfstate" # for eks-demo
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0" # terraform aws provider version
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0" # terraform kubernetes provider version
    }
  }
}

# provider

provider "aws" {
  region = var.region
}
