# locals

locals {
  account_id = data.aws_caller_identity.current.account_id
}

locals {
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  alb_security_group_id = data.terraform_remote_state.alb.outputs.security_group_id
}

locals {
  tags = {
    Name        = var.name
    ClusterName = var.name
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/8-eks"
  }
}
