# Pod Identity Association

resource "aws_eks_pod_identity_association" "eks_demo" {
  for_each = local.pod_identity_associations

  cluster_name = "eks-demo"

  namespace       = try(each.value["namespace"], each.key)
  service_account = try(each.value["service_account"], each.key)
  role_arn        = try(each.value["role_arn"], format("arn:aws:iam::%s:role/%s", local.account_id, try(each.value["role_name"], format("pod-role--%s", each.key))))
}
