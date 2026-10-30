terraform {
  required_version = "1.17.1"

  backend "s3" {
    region       = "ap-northeast-2"
    bucket       = "terraform-workshop-396608815058"
    key          = "backend/demo/agent-delivery-demo/terraform.tfstate"
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
      Project     = "terraform-env-demo/demo/8-agent-delivery"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  # 4-role이 만든 Pod Identity 역할. 이름 규칙은 4-role의 `pod-role--<policy>`입니다.
  delivery_role_arn         = "arn:aws:iam::${local.account_id}:role/pod-role--agent-delivery"
  runway_role_arn           = "arn:aws:iam::${local.account_id}:role/pod-role--agent-runway"
  external_secrets_role_arn = "arn:aws:iam::${local.account_id}:role/pod-role--external-secrets"
}
