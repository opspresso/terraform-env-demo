# eks

module "eks" {
  # source = "../../../../nalbam/terraform-aws-eks"
  source  = "nalbam/eks/aws"
  version = "~> 3.1"

  region     = local.region
  account_id = local.account_id

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

  addons_version = var.addons_version

  workers = local.workers

  tags = local.tags
}
