# locals

locals {
  azs = [for az in var.azs : format("%s%s", var.region, az)]

  public_subnets  = [for az in var.azs : var.az_subnets[az].public]
  private_subnets = [for az in var.azs : var.az_subnets[az].private]
  intra_subnets   = [for az in var.azs : var.az_subnets[az].intra if var.az_subnets[az].intra != null]

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/2-vpc"
  }

  eks_tags = {
    "kubernetes.io/cluster/eks-demo"   = "shared"
    "kubernetes.io/cluster/eks-demo-a" = "shared"
    "kubernetes.io/cluster/eks-demo-b" = "shared"
  }
}
