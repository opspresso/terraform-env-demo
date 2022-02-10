# vpc
# https://github.com/terraform-aws-modules/terraform-aws-vpc

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.6.0"

  name = var.name
  cidr = var.cidr

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  public_subnets  = ["10.10.5.0/24", "10.10.6.0/24", "10.10.7.0/24"]
  intra_subnets   = ["10.10.15.0/24", "10.10.16.0/24", "10.10.17.0/24"]

  enable_ipv6 = true

  enable_nat_gateway = true
  single_nat_gateway = true

  # enable_s3_endpoint       = true
  # enable_dynamodb_endpoint = true

  tags = {
    "kubernetes.io/cluster/eks-demo" = "shared"
  }

  vpc_tags = {
    "Name" = var.name
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/eks-demo"   = "shared"
    "kubernetes.io/cluster/eks-demo-a" = "shared"
    "kubernetes.io/cluster/eks-demo-b" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/eks-demo"   = "shared"
    "kubernetes.io/cluster/eks-demo-a" = "shared"
    "kubernetes.io/cluster/eks-demo-b" = "shared"
    "kubernetes.io/role/internal-elb"  = "1"
  }

  intra_subnet_tags = {
    "kubernetes.io/cluster/eks-demo"   = "shared"
    "kubernetes.io/cluster/eks-demo-a" = "shared"
    "kubernetes.io/cluster/eks-demo-b" = "shared"
  }
}
