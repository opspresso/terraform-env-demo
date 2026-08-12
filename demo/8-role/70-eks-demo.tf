# Pod Identity Association

locals {
  eks_demo_targets = {
    "atlantis" = {
      namespace       = "addon-atlantis"
      service_account = "atlantis"
    }
    "agentdure" = {
      namespace       = "agentdure"
      service_account = "agentdure"
    }
    "mcp-memory" = {
      namespace       = "agent-mcps"
      service_account = "mcp-memory"
    }
    "mcp-document" = {
      namespace       = "agent-mcps"
      service_account = "mcp-document"
    }
  }
}

locals {
  eks_demo_items = {
    for key, value in local.eks_demo_targets : key => {
      role_name       = aws_iam_role.this[key].name
      role_arn        = aws_iam_role.this[key].arn
      namespace       = value.namespace
      service_account = value.service_account
    }
  }
}

resource "aws_eks_pod_identity_association" "eks_demo_common" {
  for_each = local.common_items

  cluster_name = "eks-demo"

  namespace       = try(each.value["namespace"], each.key)
  service_account = try(each.value["service_account"], each.key)
  role_arn        = try(each.value["role_arn"], format("arn:aws:iam::%s:role/%s", local.account_id, try(each.value["role_name"], format("pod-role--%s", each.key))))
}

resource "aws_eks_pod_identity_association" "eks_demo" {
  for_each = local.eks_demo_items

  cluster_name = "eks-demo"

  namespace       = try(each.value["namespace"], each.key)
  service_account = try(each.value["service_account"], each.key)
  role_arn        = try(each.value["role_arn"], format("arn:aws:iam::%s:role/%s", local.account_id, try(each.value["role_name"], format("pod-role--%s", each.key))))
}
