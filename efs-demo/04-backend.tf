# backend

terraform {
  required_version = "1.0.4"

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-082867736673"
    key            = "backend/terraform-env-bruce/demo/efs-demo/terraform.tfstate"
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  #   backend "remote" {
  #     organization = "bruce"
  #     workspaces {
  #       name = "efs-demo"
  #     }
  #   }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.53.0"
    }
  }
}
