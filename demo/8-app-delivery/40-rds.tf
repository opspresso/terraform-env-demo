# Shared network objects for the RDS instances that kro RdsPostgres creates through ACK
# (argocd-env-addons charts/kro, agent-platform docs/DELIVERY_V2.md). Each instance gets its own
# DB identifier and master password; the subnet group and security group are shared and free.

# The intra subnets of 2-vpc hold only these instances: no node or Pod has an address there, so the RdsPostgres
# NetworkPolicy that opens TCP 5432 to these subnets reaches no other PostgreSQL in the cluster.
resource "aws_db_subnet_group" "rds" {
  name        = "app-delivery-rds"
  description = "Agent Delivery RdsPostgres instances"
  subnet_ids  = data.terraform_remote_state.vpc.outputs.intra_subnets
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

# Every RdsPostgres instance uses this group: rds.force_ssl rejects connections without TLS, so the instance
# credentials are never sent in clear text. The family must match the major version RDS creates by default
# (the RdsPostgres template does not pin engineVersion); a mismatch fails the instance with a terminal error.
resource "aws_db_parameter_group" "rds" {
  name        = "app-delivery-postgres18"
  family      = "postgres18"
  description = "Agent Delivery RdsPostgres instances: TLS only"

  # postgres18 already defaults rds.force_ssl to 1, so RDS keeps it as a system parameter and reports apply_method
  # pending-reboot. Declaring the same apply_method avoids a permanent plan diff; the parameter is dynamic either way.
  parameter {
    name         = "rds.force_ssl"
    value        = "1"
    apply_method = "pending-reboot"
  }
}
