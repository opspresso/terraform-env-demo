# locals

locals {
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
