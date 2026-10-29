# locals

locals {
  azs = [for az in var.azs : format("%s%s", var.region, az)]

  public_subnets  = [for az in var.azs : var.az_subnets[az].public]
  private_subnets = [for az in var.azs : var.az_subnets[az].private]
  # The vpc module places intra_subnets[i] in azs[i]. Skipping an AZ without intra would shift the later intra subnets
  # into the wrong AZ, so every AZ in var.azs must define intra (8-app-delivery needs two AZs for its DB subnet group).
  # With enable_ipv6, each subnet type takes the prefixes i * 16 (20-main.tf), so public, private and intra would
  # overlap: give each type its own prefix range before enabling IPv6.
  intra_subnets = [for az in var.azs : var.az_subnets[az].intra if var.az_subnets[az].intra != null]

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
