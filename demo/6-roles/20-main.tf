# main

resource "aws_iam_role" "this" {
  for_each = toset(local.policies)

  name = format("%s--%s", var.prefix_name, each.key)

  assume_role_policy = data.aws_iam_policy_document.this.json

  tags = merge(
    local.tags,
    {
      "Name" = format("%s--%s", var.prefix_name, each.key)
    },
  )
}

resource "aws_iam_policy" "this" {
  for_each = toset(local.policies)

  name        = format("%s--%s", var.prefix_name, each.key)
  description = format("%s--%s -- pod identity", var.prefix_name, each.key)

  policy = file(format("%s/policies/%s.json", path.module, each.key))

  tags = merge(
    local.tags,
    {
      "Name" = format("%s--%s", var.prefix_name, each.key)
    },
  )
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(local.policies)

  role       = aws_iam_role.this[each.key].name
  policy_arn = aws_iam_policy.this[each.key].arn

  depends_on = [
    aws_iam_role.this,
    aws_iam_policy.this,
  ]
}

resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each = local.additional_policies

  role       = aws_iam_role.this[each.key].name
  policy_arn = each.value.policy

  depends_on = [
    aws_iam_role.this,
  ]
}
