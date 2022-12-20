# backend

terraform {
  required_version = "1.3.6" # terraform version

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-082867736673"
    key            = "backend/demo/efs-demo/terraform.tfstate"
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.48.0" # terraform aws provider version
    }
  }
}
