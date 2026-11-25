# Public routing and cluster identifiers that other stacks and installers read by name.
# The names are the earlier SSM parameter names; the values are plain strings.
locals {
  published_metadata = {
    public_grpc_0   = aws_lb_target_group.public_grpc_0.arn
    public_http_0   = aws_lb_target_group.public_http_0.arn
    public_http_a   = aws_lb_target_group.public_http_a.arn
    public_http_b   = aws_lb_target_group.public_http_b.arn
    internal_http_0 = aws_lb_target_group.internal_http_0.arn
    internal_http_a = aws_lb_target_group.internal_http_a.arn
    internal_http_b = aws_lb_target_group.internal_http_b.arn
  }
}

resource "aws_secretsmanager_secret" "metadata" {
  for_each = local.published_metadata
  name     = "/k8s/common/${var.name}/${each.key}"
}

resource "aws_secretsmanager_secret_version" "metadata" {
  for_each      = local.published_metadata
  secret_id     = aws_secretsmanager_secret.metadata[each.key].id
  secret_string = each.value
}
