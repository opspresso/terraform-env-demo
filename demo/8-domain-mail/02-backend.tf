terraform {
  required_version = ">= 1.15.8, < 2.0"

  backend "s3" {
    region       = "ap-northeast-2"
    bucket       = "terraform-workshop-396608815058"
    key          = "backend/demo/domain-mail/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.60.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.7.1"
    }
  }
}

provider "aws" {
  region              = var.region
  allowed_account_ids = ["396608815058"]
  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Project   = "terraform-env-demo/demo/8-domain-mail"
    }
  }
}
