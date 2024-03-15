# eks
# https://github.com/terraform-aws-modules/terraform-aws-eks

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  # IPV6
  cluster_ip_family          = var.ip_family
  create_cni_ipv6_iam_policy = var.ip_family == "ipv6" ? true : false

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  # Enable EFA support by adding necessary security group rules
  # to the shared node security group
  enable_efa_support = true

  cluster_addons = local.cluster_addons

  self_managed_node_group_defaults = local.self_managed_node_group_defaults
  self_managed_node_groups         = local.self_managed_node_groups

  tags = local.tags
}
