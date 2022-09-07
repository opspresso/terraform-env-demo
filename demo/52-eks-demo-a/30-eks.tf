# eks

module "eks" {
  source = "nalbam/eks/aws"
  # version = "1.1.x"

  cluster_name = var.cluster_name

  kubernetes_version = var.kubernetes_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  endpoint_public_access = true

  # ip_family = "ipv6"

  cluster_log_types = []

  iam_group = local.iam_group
  iam_roles = local.iam_roles

  worker_source_sgs = local.worker_source_sgs

  addons_version   = var.addons_version
  addons_irsa_name = var.addons_irsa_name

  tags = local.tags
}

# tf state rm module.eks.kubernetes_config_map.aws_auth
# tf import module.eks.kubernetes_config_map.aws_auth kube-system/aws-auth
