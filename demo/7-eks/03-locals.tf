# locals

locals {
  region = var.region

  account_id = data.aws_caller_identity.current.account_id
}

locals {
  # cluster_name = var.cluster_name

  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  vpc_security_group_ids = [
    data.terraform_remote_state.vpc.outputs.default_security_group_id,
    data.terraform_remote_state.alb.outputs.security_group_id,
  ]

  tags = {
    Name        = var.cluster_name
    ClusterName = var.cluster_name
    Environment = "demo"
  }
}
