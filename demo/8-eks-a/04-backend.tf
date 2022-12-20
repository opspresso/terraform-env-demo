# backend

terraform {
  required_version = "1.3.6" # terraform version

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-082867736673"
    key            = "backend/demo/eks-demo-a/terraform.tfstate" # for eks-demo-a
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0" # terraform aws provider version
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.5" # terraform kubernetes provider version
    }
  }
}
