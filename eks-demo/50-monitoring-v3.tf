# worker

module "monitoring-v3" {
  source  = "nalbam/eks-worker/aws"
  version = "0.14.2"

  name    = "monitoring"
  subname = "v3"

  cluster_info = module.eks.cluster_info

  role_name         = local.worker_role_name
  security_groups   = local.worker_security_groups
  subnet_ids        = data.aws_subnet_ids.b.ids
  target_group_arns = []

  worker_ami_arch    = "arm64"
  worker_ami_keyword = "*"

  key_name = var.key_name

  enable_autoscale = true
  enable_taints    = true
  enable_spot      = true

  instance_type = "r6g.large"
  volume_type   = "gp3"
  volume_size   = "50"

  min = 1
  max = 1

  tags = local.tags
}
