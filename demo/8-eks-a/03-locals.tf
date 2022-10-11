# locals

locals {
  account_id = data.aws_caller_identity.current.account_id
}

locals {
  cluster_name = var.cluster_name

  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets
  # intra_subnets   = data.terraform_remote_state.vpc.outputs.intra_subnets

  provider_url = module.eks.cluster_oidc_url

  worker_role_arn  = module.eks.worker_role_arn
  worker_role_name = module.eks.worker_role_name

  instance_profile_name = module.eks.worker_instance_profile_name

  worker_source_sgs = [
    data.terraform_remote_state.alb.outputs.security_group_id,
  ]

  worker_security_groups = [
    module.eks.worker_security_group,
    data.terraform_remote_state.vpc.outputs.default_security_group_id,
  ]

  tags = {
    Name        = local.cluster_name
    Environment = "demo"
  }
}

locals {
  iam_group = "admin"

  iam_roles = [
    {
      name   = "system:node:{{EC2PrivateDNSName}}"
      role   = format("arn:aws:iam::%s:role/%s", local.account_id, local.worker_role_name)
      groups = ["system:bootstrappers", "system:nodes"]
    },
    {
      name   = "atlantis-ecs"
      role   = format("arn:aws:iam::%s:role/atlantis-ecs_task_execution", local.account_id)
      groups = ["system:masters"]
    },
    {
      name   = "atlantis-eks"
      role   = format("arn:aws:iam::%s:role/irsa--%s--atlantis", local.account_id, "eks-demo")
      groups = ["system:masters"]
    },
    {
      name   = "k8s-master"
      role   = format("arn:aws:iam::%s:role/k8s-master", local.account_id)
      groups = ["system:masters"]
    },
    {
      name   = "k8s-readonly"
      role   = format("arn:aws:iam::%s:role/k8s-readonly", local.account_id)
      groups = []
    },
  ]
}
