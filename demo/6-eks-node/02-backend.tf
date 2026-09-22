# backend

terraform {
  required_version = "1.15.8" # terraform version

  backend "s3" {
    region  = "ap-northeast-2"
    bucket  = "terraform-workshop-396608815058"
    key     = "backend/demo/eks-node-demo/terraform.tfstate"
    encrypt = true
  }

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.2.1" # terraform kubernetes provider version
    }
  }
}

# provider

provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.terraform_remote_state.eks.outputs.cluster_name,
      "--region",
      data.terraform_remote_state.eks.outputs.cluster_region,
    ]
  }
}
