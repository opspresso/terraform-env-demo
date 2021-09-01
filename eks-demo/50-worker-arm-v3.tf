# worker

module "worker-arm-v3" {
  source  = "nalbam/eks-worker/aws"
  version = "0.14.2"

  name    = "arm"
  subname = "v3"

  cluster_info = module.eks.cluster_info

  role_name         = local.worker_role_name
  security_groups   = local.worker_security_groups
  subnet_ids        = local.subnet_ids
  target_group_arns = []

  worker_ami_keyword = var.worker_ami_keyword

  key_name = var.key_name

  enable_autoscale = true
  enable_taints    = true
  enable_spot      = true

  instance_type = "c5a.large"
  volume_type   = "gp3"
  volume_size   = "50"

  min = 1
  max = 6

  tags = local.tags
}
