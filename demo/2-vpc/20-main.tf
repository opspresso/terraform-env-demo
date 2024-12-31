# vpc
# https://github.com/terraform-aws-modules/terraform-aws-vpc

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  azs = [
    format("%sa", var.region),
    format("%sb", var.region),
    format("%sc", var.region),
  ]

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  intra_subnets   = var.intra_subnets

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  enable_ipv6 = var.enable_ipv6

  public_subnet_ipv6_prefixes = [
    for i in range(length(var.public_subnets)) : i * 16
  ]
  public_subnet_assign_ipv6_address_on_creation = var.enable_ipv6

  private_subnet_ipv6_prefixes = [
    for i in range(length(var.private_subnets)) : i * 16
  ]
  private_subnet_assign_ipv6_address_on_creation = var.enable_ipv6

  intra_subnet_ipv6_prefixes = [
    for i in range(length(var.intra_subnets)) : i * 16
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
