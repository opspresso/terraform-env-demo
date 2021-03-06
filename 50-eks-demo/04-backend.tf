# backend

terraform {
  required_version = "1.1.9"

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-082867736673"
    key            = "backend/demo/eks-demo/terraform.tfstate" # for eks-demo
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.11.0"
    }
  }
}
