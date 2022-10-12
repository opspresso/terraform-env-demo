# eks

module "eks" {
  # source = "../../../../nalbam/terraform-aws-eks"
  source = "nalbam/eks/aws"
  # version = "2.1.x"

  cluster_name = var.cluster_name

  kubernetes_version = var.kubernetes_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  endpoint_public_access = true

  ip_family = var.ip_family

  cluster_log_types = []

  iam_group = local.iam_group
  iam_roles = local.iam_roles

  worker_source_sgs = local.worker_source_sgs

  addons_version   = var.addons_version
  addons_irsa_name = var.addons_irsa_name

  apply_aws_auth = true

  tags = local.tags
}

# tf state rm module.eks.kubernetes_config_map.aws_auth
