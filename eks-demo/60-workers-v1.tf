# worker

module "workers-v1" {
  source  = "nalbam/eks-nodegroup/aws"
  version = "0.14.3"

  name    = "workers"
  subname = "v1"

  cluster_name = local.cluster_name

  node_role_arn   = local.worker_role_arn
  security_groups = local.worker_security_groups
  subnet_ids      = local.subnet_ids

  key_name = var.key_name

  enable_taints = false
  enable_spot   = true

  ami_type       = "AL2_x86_64"
  instance_types = ["c5.large"]

  volume_type = "gp3"
  volume_size = "50"

  min = 2
  max = 6

  tags = local.tags
}
