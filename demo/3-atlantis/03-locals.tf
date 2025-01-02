# locals

locals {
  vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr_block = data.terraform_remote_state.vpc.outputs.vpc_cidr_block

  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets
  public_subnet_ids  = data.terraform_remote_state.vpc.outputs.public_subnets

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/3-atlantis"
  }
}
