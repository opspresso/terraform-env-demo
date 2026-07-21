# Pod Identity Association

locals {
  pod_identity_associations = data.terraform_remote_state.role.outputs.pod_identity_associations
}

resource "aws_eks_pod_identity_association" "this" {
  for_each = local.pod_identity_associations

  cluster_name = module.eks.cluster_name

  namespace       = try(each.value["namespace"], each.key)
  service_account = try(each.value["service_account"], each.key)
  role_arn        = try(each.value["role_arn"], format("arn:aws:iam::%s:role/%s", local.account_id, try(each.value["role_name"], format("pod-role--%s", each.key))))

  tags = merge(
    local.tags,
    {
      "Name" = format("%s--%s--%s", var.cluster_name, try(each.value["namespace"], each.key), try(each.value["service_account"], each.key))
    },
  )
}
