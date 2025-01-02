# eks
# https://github.com/terraform-aws-modules/terraform-aws-eks

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  # ipv6
  cluster_ip_family          = var.ip_family
  create_cni_ipv6_iam_policy = var.ip_family == "ipv6" ? true : false

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  # # EKS Auto Mode
  # cluster_compute_config = {
  #   enabled    = true
  #   node_pools = ["general-purpose"]
  # }

  cluster_addons = local.cluster_addons

  access_entries = local.access_entries

  self_managed_node_group_defaults = local.self_managed_node_group_defaults
  self_managed_node_groups         = local.self_managed_node_groups

  node_security_group_additional_rules = local.node_security_group_additional_rules

  tags = local.tags
}
