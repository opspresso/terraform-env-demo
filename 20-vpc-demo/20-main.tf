# vpc
# https://github.com/terraform-aws-modules/terraform-aws-vpc

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # version = "3.12.0"

  name = var.name
  cidr = var.cidr

  azs             = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
  public_subnets  = ["10.10.11.0/24", "10.10.12.0/24", "10.10.13.0/24"]
  private_subnets = ["10.10.21.0/24", "10.10.22.0/24", "10.10.23.0/24"]
  intra_subnets   = ["10.10.31.0/24", "10.10.32.0/24", "10.10.33.0/24"]

  enable_ipv6 = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags

  vpc_tags = local.eks_tags

  public_subnet_tags = merge(
    { "kubernetes.io/role/elb" = "1" },
    local.tags,
    local.eks_tags,
  )

  private_subnet_tags = merge(
    { "kubernetes.io/role/internal-elb" = "1" },
    local.tags,
    local.eks_tags,
  )

  intra_subnet_tags = merge(
    local.tags,
    local.eks_tags,
  )
}
