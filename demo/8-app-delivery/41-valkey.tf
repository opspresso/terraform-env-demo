# Security group of the ElastiCache Serverless Valkey caches that kro ValkeyCache creates through ACK
# (argocd-env-addons charts/kro, agent-platform docs/DELIVERY_V2.md). The caches use the intra subnets of 2-vpc,
# like the RDS instances; each cache has its own user and password, and accepts TLS connections only.

resource "aws_security_group" "valkey" {
  name        = "app-delivery-valkey"
  description = "Agent Runway ValkeyCache serverless caches"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "app-delivery-valkey"
  }
}

# Only EKS Pods reach the caches. Which namespace may connect is decided in the cluster: the ValkeyCache
# NetworkPolicy opens TCP 6379 for its own namespace only. The reader endpoint port 6380 stays closed.
resource "aws_vpc_security_group_ingress_rule" "valkey_from_eks" {
  security_group_id = aws_security_group.valkey.id

  description                  = "EKS cluster primary security group to Valkey"
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6379
  referenced_security_group_id = data.terraform_remote_state.eks.outputs.workspace_security_group_id

  tags = {
    Name = "app-delivery-valkey-from-eks"
  }
}

# The ACK ElastiCache controller attaches this exact security group to the serverless cache endpoints.
# The group ID exists only after this stack is applied, so this grant lives here instead of the 4-role policy,
# where a Name tag condition would also match any other group given the same tag.
resource "aws_iam_role_policy" "ack_elasticache_endpoint_security_group" {
  name = "valkey-endpoint-security-group"
  role = "pod-role--ack-elasticache"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "ServerlessEndpointSecurityGroup"
      Effect   = "Allow"
      Action   = "ec2:CreateVpcEndpoint"
      Resource = "arn:aws:ec2:${var.region}:${local.account_id}:security-group/${aws_security_group.valkey.id}"
    }]
  })
}
