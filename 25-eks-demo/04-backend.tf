# backend

terraform {
  required_version = "1.0.4"

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-082867736673"
    key            = "backend/terraform-env-bruce/demo/eks-demo/terraform.tfstate"
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.56.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.4.1" # 1.13.4
    }
  }
}
