# eks
# https://github.com/terraform-aws-modules/terraform-aws-eks

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name = var.name

  kubernetes_version = var.kubernetes_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  ip_family                  = var.ip_family
  create_cni_ipv6_iam_policy = var.ip_family == "ipv6" ? true : false

  endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  # EKS Auto Mode
  compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  access_entries = local.access_entries

  addons = local.cluster_addons

  eks_managed_node_groups = local.eks_managed_node_groups

  self_managed_node_groups = local.self_managed_node_groups

  node_security_group_additional_rules = local.node_security_group_additional_rules

  tags = local.tags
}
