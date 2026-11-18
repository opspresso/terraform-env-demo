resource "aws_iam_role" "this" {
  for_each = local.roles

  name = format("%s--%s", local.prefix_name, each.key)

  # 같은 계정의 EKS Pod Identity 만 이 역할을 맡을 수 있도록 제한합니다.
  # 클러스터 단위로 더 좁히려면 aws:SourceArn 에 클러스터 ARN 을 추가합니다.
  assume_role_policy = templatefile("${path.module}/policies/trust/pod-identity.json", { account_id = local.account_id })

  tags = {
    Name = format("%s--%s", local.prefix_name, each.key)
  }
}

resource "aws_iam_policy" "this" {
  for_each = toset(local.policies)

  name        = format("%s--%s", local.prefix_name, each.key)
  description = format("%s--%s -- pod identity", local.prefix_name, each.key)

  policy = file(format("%s/policies/%s.json", path.module, each.key))

  tags = {
    Name = format("%s--%s", local.prefix_name, each.key)
  }
}

# role/policy 를 직접 참조하므로 의존성은 암시적으로 결정됩니다.

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(local.policies)

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.this[each.key].arn
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each = local.additional_policies

  role       = aws_iam_role.this[each.key].name
  policy_arn = each.value.policy
}
