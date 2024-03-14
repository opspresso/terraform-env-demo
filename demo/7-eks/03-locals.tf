# locals

locals {
  region = var.region

  account_id = data.aws_caller_identity.current.account_id
}

locals {
  cluster_name = var.cluster_name

  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
  # intra_subnets   = data.terraform_remote_state.vpc.outputs.intra_subnets

  # provider_url = module.eks.cluster_oidc_url

  # worker_role_arn  = module.eks.worker_role_arn
  # worker_role_name = module.eks.worker_role_name

  # instance_profile_name = module.eks.worker_instance_profile_name

  worker_source_sgs = [
    data.terraform_remote_state.alb.outputs.security_group_id,
  ]

  worker_security_groups = [
    # module.eks.worker_security_group,
    data.terraform_remote_state.vpc.outputs.default_security_group_id,
  ]

  # worker_ami_id = module.eks.worker_ami_id

  tags = {
    Name        = local.cluster_name
    Environment = "demo"
  }
}
