# EKS Auto Mode nodes use the EKS-managed cluster primary security group,
# not the security groups created by the eks module.

resource "aws_vpc_security_group_ingress_rule" "alb_to_node_80" {
  security_group_id = module.eks.cluster_primary_security_group_id

  description                  = "ALB to node 80/tcp"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = local.alb_security_group_id

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-alb-to-node-80", var.name)
    },
  )
}

resource "aws_vpc_security_group_ingress_rule" "alb_to_node_15021" {
  security_group_id = module.eks.cluster_primary_security_group_id

  description                  = "ALB to node 15021/tcp health check"
  ip_protocol                  = "tcp"
  from_port                    = 15021
  to_port                      = 15021
  referenced_security_group_id = local.alb_security_group_id

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-alb-to-node-15021", var.name)
    },
  )
}
