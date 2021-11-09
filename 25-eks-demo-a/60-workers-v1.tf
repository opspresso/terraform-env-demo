# worker workers

module "workers-v1" {
  source  = "nalbam/eks-worker/aws"
  version = "0.14.8"

  name    = "workers"
  subname = "v1"

  cluster_info = module.eks.cluster_info

  role_name       = local.worker_role_name
  security_groups = local.worker_security_groups
  subnet_ids      = local.subnet_ids

  worker_ami_arch    = "x86_64"
  worker_ami_keyword = "*"

  key_name = var.key_name

  enable_autoscale = true
  enable_taints    = false
  enable_spot      = false

  instance_type = "c5.xlarge"
  volume_type   = "gp3"
  volume_size   = "30"

  min = 2
  max = 6

  tags = local.tags
}