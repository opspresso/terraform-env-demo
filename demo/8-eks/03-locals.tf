# locals

locals {
  account_id = data.aws_caller_identity.current.account_id
}

locals {
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  alb_security_group_ids = {
    public   = data.terraform_remote_state.alb.outputs.security_group_id
    internal = data.terraform_remote_state.alb.outputs.internal_security_group_id
  }

  # 80: 서비스 트래픽, 15021: istio-proxy health check
  alb_to_node_ports = [80, 15021]

  alb_to_node_rules = {
    for pair in setproduct(keys(local.alb_security_group_ids), local.alb_to_node_ports) :
    format("%s-%d", pair[0], pair[1]) => {
      source            = pair[0]
      port              = pair[1]
      security_group_id = local.alb_security_group_ids[pair[0]]
    }
  }
}

locals {
  tags = {
    ClusterName = var.name
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/8-eks"
  }
}
