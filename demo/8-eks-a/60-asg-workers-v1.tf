# worker workers

module "workers-v1" {
  source = "nalbam/eks-worker/aws"
  # version = "~> 3.0"

  name    = "workers"
  subname = "v1"

  region     = local.region
  account_id = local.account_id

  cluster_name = local.cluster_name

  cluster_endpoint              = module.eks.cluster_endpoint
  cluster_certificate_authority = module.eks.cluster_certificate_authority

  ami_id          = local.worker_ami_id
  role_name       = local.worker_role_name
  security_groups = local.worker_security_groups
  subnet_ids      = local.private_subnets

  kubernetes_version = var.kubernetes_version

  key_name = var.key_name

  enable_autoscale = true
  enable_mixed     = true
  enable_taints    = false

  on_demand_base = 0
  on_demand_rate = 0

  mixed_instances = ["c6i.xlarge", "c5.xlarge"]
  volume_type     = "gp3"
  volume_size     = "50"

  min = 2
  max = 12

  tags = local.tags

  depends_on = [
    module.eks,
  ]
}
