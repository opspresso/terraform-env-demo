# locals

locals {
  tags = {
    Environment = "demo"
  }

  eks_tags = {
    "kubernetes.io/cluster/eks-demo"   = "shared"
    "kubernetes.io/cluster/eks-demo-a" = "shared"
    "kubernetes.io/cluster/eks-demo-b" = "shared"
  }
}
