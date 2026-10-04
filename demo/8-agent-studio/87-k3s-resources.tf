# Apply to existing nodes as well as new nodes; user_data is intentionally ignored
# after bootstrap. The script restarts k3s only when this owned drop-in changes.
resource "aws_ssm_association" "k3s_resources" {
  name             = "AWS-RunShellScript"
  association_name = "k3s-alpha-resource-profile"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.k3s.id]
  }

  parameters = {
    commands = "bash -s -- '${var.k3s_go_memory_limit_mib}' <<'K3S_RESOURCE_PROFILE'\n${file("${path.module}/configure-k3s-resources.sh")}\nK3S_RESOURCE_PROFILE"
  }

  schedule_expression              = "rate(1 day)"
  wait_for_success_timeout_seconds = 300

  depends_on = [aws_iam_role_policy_attachment.k3s_ssm_core]
}
