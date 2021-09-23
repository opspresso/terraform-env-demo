# worker

module "monitoring-v2" {
  source  = "nalbam/eks-worker/aws"
  version = "0.14.6"

  name    = "monitoring"
  subname = "v2"

  cluster_info = module.eks.cluster_info

  role_name       = local.worker_role_name
  security_groups = local.worker_security_groups
  subnet_ids      = data.aws_subnet_ids.b.ids

  worker_ami_arch    = "arm64"
  worker_ami_keyword = "*"

  key_name = var.key_name

  enable_autoscale = true
  enable_taints    = true
  enable_spot      = false

  instance_type = "r6g.large"
  volume_type   = "gp3"
  volume_size   = "30"

  min = 1
  max = 1

  tags = local.tags
}
