# locals

locals {
  account_id = data.aws_caller_identity.current.account_id
}

locals {
  cluster_name = var.cluster_name

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  worker_role_name = module.eks.worker_role_name

  worker_security_groups = [
    module.eks.worker_security_group,
  ]

  tags = {
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
