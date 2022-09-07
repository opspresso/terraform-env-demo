# locals

locals {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  vgw_id = data.terraform_remote_state.vpc.outputs.vgw_id

  vpc_cidr_block = data.terraform_remote_state.vpc.outputs.vpc_cidr_block

  private_route_table_ids = data.terraform_remote_state.vpc.outputs.private_route_table_ids

  cgw_ids = [for k, v in aws_customer_gateway.this : v.id]

  tags = {
    Environment = "demo"
  }
}
