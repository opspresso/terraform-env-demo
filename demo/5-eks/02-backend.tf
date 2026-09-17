# backend

terraform {
  required_version = "1.15.8" # terraform version

  backend "s3" {
    region  = "ap-northeast-2"
    bucket  = "terraform-workshop-396608815058"
    key     = "backend/demo/eks-demo/terraform.tfstate" # for eks-demo
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.60.0" # terraform aws provider version
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

# provider

provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--region",
      var.region,
    ]
  }
}
