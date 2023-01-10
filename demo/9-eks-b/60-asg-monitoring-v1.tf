# worker monitoring

module "monitoring-v1" {
  source  = "nalbam/eks-worker/aws"
  version = "~> 2.3"

  name    = "monitoring"
  subname = "v1"

  cluster_name = local.cluster_name

  role_name       = local.worker_role_name
  security_groups = local.worker_security_groups
  subnet_ids      = data.aws_subnets.c.ids

  kubernetes_version = var.kubernetes_version
  worker_ami_arch    = "x86_64"
  worker_ami_keyword = "*"

  key_name = var.key_name

  enable_autoscale = true
  enable_mixed     = true
  enable_taints    = true

  on_demand_base = 0
  on_demand_rate = 0

  mixed_instances = ["m6i.large", "m5.large"]
  volume_type     = "gp3"
  volume_size     = "50"

  min = 1
  max = 1

  tags = local.tags

  depends_on = [
    module.eks,
  ]
}
