# eks

module "eks" {
  source  = "nalbam/eks/aws"
  version = "0.14.8"

  cluster_name = var.cluster_name

  kubernetes_version = var.cluster_version

  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids

  endpoint_public_access = true

  iam_group = local.iam_group
  iam_roles = local.iam_roles

  worker_policies = [
    aws_iam_policy.worker-ce.arn,
  ]

  tags = local.tags
}
