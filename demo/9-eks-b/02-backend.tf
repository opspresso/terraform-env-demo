# backend

terraform {
  required_version = "1.5.7" # terraform version

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-082867736673"
    key            = "backend/demo/eks-demo-b/terraform.tfstate" # for eks-demo-b
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.32.1" # terraform aws provider version
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.23.0" # terraform kubernetes provider version
    }
  }
}
