# EKS Auto Mode nodes use the EKS-managed cluster primary security group,
# not the security groups created by the eks module.

resource "aws_vpc_security_group_ingress_rule" "alb_to_node" {
  for_each = local.alb_to_node_rules

  security_group_id = module.eks.cluster_primary_security_group_id

  description                  = format("%s ALB to node %d/tcp", each.value.source, each.value.port)
  ip_protocol                  = "tcp"
  from_port                    = each.value.port
  to_port                      = each.value.port
  referenced_security_group_id = each.value.security_group_id

  tags = {
    Name = format("%s-alb-to-node-%s", var.name, each.key)
  }
}
