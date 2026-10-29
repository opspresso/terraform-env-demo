# Service-linked roles that the ACK controllers need on their first create call. Without them, the first
# CreateDBInstance fails with a terminal "Missing necessary credentials ... ServiceLinkedRoles" error while AWS creates
# the role, and the first CreateServerlessCache can fail the same way. Declaring them keeps a new account working.
# They are account-wide and shared with anything else that uses RDS or ElastiCache, so they are never destroyed here.

# AWSServiceRoleForRDS already exists in this account (created on the first RdsPostgres).
import {
  to = aws_iam_service_linked_role.rds
  id = "arn:aws:iam::${local.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
}

resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"
  # The description RDS gave the role; leaving it unset would clear it.
  description = "Allows Amazon RDS to manage AWS resources on your behalf"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_service_linked_role" "elasticache" {
  aws_service_name = "elasticache.amazonaws.com"
  description      = "Allows ElastiCache to manage AWS resources for your cache on your behalf"

  lifecycle {
    prevent_destroy = true
  }
}
