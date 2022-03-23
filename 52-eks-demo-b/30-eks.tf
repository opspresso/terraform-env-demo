# eks

module "eks" {
  source = "nalbam/eks/aws"
  # version = "0.14.12"

  cluster_name = var.cluster_name

  kubernetes_version = var.kubernetes_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  endpoint_public_access = true

  cluster_log_types = []

  iam_group = local.iam_group
  iam_roles = local.iam_roles

  worker_policies   = local.worker_policies
  worker_source_sgs = local.worker_source_sgs

  tags = local.tags
}

# tf state rm module.eks.kubernetes_config_map.aws_auth
# tf import module.eks.kubernetes_config_map.aws_auth kube-system/aws-auth