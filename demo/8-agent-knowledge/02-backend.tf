terraform {
  required_version = "1.17.1"

  backend "s3" {
    region       = "ap-northeast-2"
    bucket       = "terraform-workshop-396608815058"
    key          = "backend/demo/agent-knowledge-demo/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.71.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "demo"
      ManagedBy   = "Terraform"
      Project     = "terraform-env-demo/demo/8-agent-knowledge"
    }
  }
}
