# locals

locals {
  account_id = data.aws_caller_identity.current.account_id
}

locals {
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  # vpc_security_group_ids = [
  #   data.terraform_remote_state.vpc.outputs.default_security_group_id,
  #   data.terraform_remote_state.alb.outputs.security_group_id,
  # ]

  node_security_group_additional_rules = {
    # ingress_all_self_node = {
    #   description = "Node to node all"
    #   protocol    = "-1"
    #   from_port   = 0
    #   to_port     = 0
    #   type        = "ingress"
    #   self        = true
    # }
    # ingress_all_self_cluster = {
    #   description                   = "Cluster API to node all"
    #   protocol                      = "-1"
    #   from_port                     = 0
    #   to_port                       = 0
    #   type                          = "ingress"
    #   source_cluster_security_group = true
    # }
    # istio
    ingress_cluster_15017_webhook = {
      description                   = "Cluster API to node 15017/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # alb http
    ingress_alb_80 = {
      description              = "ALB to node 80/tcp"
      protocol                 = "tcp"
      from_port                = 80
      to_port                  = 80
      type                     = "ingress"
      source_security_group_id = data.terraform_remote_state.alb.outputs.security_group_id
    }
    # alb health
    ingress_alb_15021 = {
      description              = "ALB to node 15021/tcp"
      protocol                 = "tcp"
      from_port                = 15021
      to_port                  = 15021
      type                     = "ingress"
      source_security_group_id = data.terraform_remote_state.alb.outputs.security_group_id
    }
  }
}

locals {
  tags = {
    Name        = var.cluster_name
    ClusterName = var.cluster_name
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/7-eks"
  }
}
