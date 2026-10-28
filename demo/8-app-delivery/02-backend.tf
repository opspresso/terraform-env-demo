terraform {
  required_version = "1.15.8"

  backend "s3" {
    region       = "ap-northeast-2"
    bucket       = "terraform-workshop-396608815058"
    key          = "backend/demo/app-delivery-demo/terraform.tfstate"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.60.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = "demo"
      ManagedBy   = "Terraform"
      Project     = "terraform-env-demo/demo/8-app-delivery"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  # 4-role이 만든 Delivery registry 단계의 Pod Identity 역할. 이름 규칙은 4-role의 `pod-role--<policy>`입니다.
  registry_role_arn = "arn:aws:iam::${local.account_id}:role/pod-role--app-delivery"
  # Session tags that EKS Pod Identity adds to every credential; they are transitive.
  pod_identity_tag_keys = ["eks-cluster-arn", "eks-cluster-name", "kubernetes-namespace", "kubernetes-service-account", "kubernetes-pod-name", "kubernetes-pod-uid"]
}
