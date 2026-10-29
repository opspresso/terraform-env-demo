# Shared network objects for the RDS instances that kro RdsPostgres creates through ACK
# (argocd-env-addons charts/kro, agent-platform docs/DELIVERY_V2.md). Each instance gets its own
# DB identifier and master password; the subnet group and security group are shared and free.

resource "aws_db_subnet_group" "rds" {
  name        = "app-delivery-rds"
  description = "Agent Delivery RdsPostgres instances"
  subnet_ids  = data.terraform_remote_state.vpc.outputs.private_subnets
}

resource "aws_security_group" "rds" {
  name        = "app-delivery-rds"
  description = "Agent Delivery RdsPostgres instances"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "app-delivery-rds"
  }
}

# Only EKS Pods reach the instances. Which namespace may connect is decided in the cluster:
# the RdsPostgres NetworkPolicy opens TCP 5432 for its own namespace only.
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id = aws_security_group.rds.id

  description                  = "EKS cluster primary security group to PostgreSQL"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = data.terraform_remote_state.eks.outputs.workspace_security_group_id

  tags = {
    Name = "app-delivery-rds-from-eks"
  }
}
