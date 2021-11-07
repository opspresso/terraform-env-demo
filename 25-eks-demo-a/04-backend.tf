# backend

terraform {
  required_version = "1.0.10"

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-082867736673"
    key            = "backend/terraform-env-bruce/demo/eks-demo-a/terraform.tfstate"
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.64.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.6.1"
    }
  }
}
