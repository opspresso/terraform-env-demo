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

  public_subnets  = ["10.10.16.0/20", "10.10.32.0/20", "10.10.48.0/20"]
  private_subnets = ["10.10.112.0/20", "10.10.128.0/20", "10.10.144.0/20"]
  # intra_subnets = ["10.10.208.0/20", "10.10.224.0/20", "10.10.240.0/20"]

  public_subnet_ipv6_prefixes                   = [16, 32, 48]
  public_subnet_assign_ipv6_address_on_creation = true

  private_subnet_ipv6_prefixes                   = [112, 128, 144]
  private_subnet_assign_ipv6_address_on_creation = true

  # intra_subnet_ipv6_prefixes                   = [208, 224, 240]
  # intra_subnet_assign_ipv6_address_on_creation = true

  enable_ipv6 = true

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  # enable_vpn_gateway = true
  # amazon_side_asn    = 64620

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
