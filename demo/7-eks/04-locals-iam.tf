# locals iam

locals {
  iam_group = "admin"

  iam_roles = [
    # {
    #   name   = "system:node:{{EC2PrivateDNSName}}"
    #   role   = format("arn:aws:iam::%s:role/%s", local.account_id, local.worker_role_name)
    #   groups = ["system:bootstrappers", "system:nodes"]
    # },
    # {
    #   name   = "atlantis-ecs"
    #   role   = format("arn:aws:iam::%s:role/atlantis-ecs_task_execution", local.account_id)
    #   groups = ["system:masters"]
    # },
    # {
    #   name   = "atlantis-eks"
    #   role   = format("arn:aws:iam::%s:role/irsa--%s--atlantis", local.account_id, var.cluster_name)
    #   groups = ["system:masters"]
    # },
    # {
    #   name   = "k8s-master"
    #   role   = format("arn:aws:iam::%s:role/k8s-master", local.account_id)
    #   groups = ["system:masters"]
    # },
    # {
    #   name   = "k8s-readonly"
    #   role   = format("arn:aws:iam::%s:role/k8s-readonly", local.account_id)
    #   groups = []
    # },
  ]
}
