# worker

module "worker-monitoring-v2" {
  source  = "nalbam/eks-worker/aws"
  version = "0.14.2"

  name    = "monitoring"
  subname = "v2"

  cluster_info = module.eks.cluster_info

  role_name         = local.worker_role_name
  security_groups   = local.worker_security_groups
  subnet_ids        = data.aws_subnet_ids.b.ids
  target_group_arns = []

  worker_ami_keyword = var.worker_ami_keyword

  key_name = var.key_name

  enable_autoscale = true
  enable_taints    = true

  instance_type = "c5.large"
  volume_type   = "gp3"
  volume_size   = "100"

  min = 1
  max = 1

  tags = local.tags
}
