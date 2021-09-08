# locals

locals {
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  security_groups = [
    data.terraform_remote_state.vpc.outputs.default_security_group_id,
    aws_security_group.public.id,
  ]
}
