# vpc
# https://github.com/terraform-aws-modules/terraform-aws-vpc

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = var.name
  cidr = var.cidr

  azs = local.azs

  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  intra_subnets   = local.intra_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  enable_ipv6 = var.enable_ipv6

  public_subnet_ipv6_prefixes = [
    for i in range(length(local.public_subnets)) : i * 16
  ]
  public_subnet_assign_ipv6_address_on_creation = var.enable_ipv6

  private_subnet_ipv6_prefixes = [
    for i in range(length(local.private_subnets)) : i * 16
  ]
  private_subnet_assign_ipv6_address_on_creation = var.enable_ipv6

  intra_subnet_ipv6_prefixes = [
    for i in range(length(local.intra_subnets)) : i * 16
  ]
  intra_subnet_assign_ipv6_address_on_creation = var.enable_ipv6

  enable_dns_hostnames = var.enable_dns_hostnames

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

  # intra_subnet_tags = merge(
  #   local.tags,
  #   local.eks_tags,
  # )
}
