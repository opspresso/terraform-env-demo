# IAM Identity Center creates one role per permission set with a random suffix. A permission set without a
# role in this account (not assigned, or another account) gets no access entry instead of failing the plan.
data "aws_iam_roles" "sso_admin" {
  for_each = toset(var.sso_admin_permission_sets)

  name_regex  = format("^AWSReservedSSO_%s_[0-9a-f]+$", each.value)
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

locals {
  access_entries = {
    for name, roles in data.aws_iam_roles.sso_admin : replace(name, "-", "_") => {
      principal_arn = one(roles.arns)
      type          = "STANDARD"

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    } if length(roles.arns) > 0
  }
}
