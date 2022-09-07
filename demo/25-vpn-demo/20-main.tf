# vpn
# https://github.com/terraform-aws-modules/terraform-aws-vpn-gateway

resource "aws_customer_gateway" "this" {
  for_each = var.customer_gateways

  bgp_asn     = each.value["bgp_asn"]
  ip_address  = each.value["ip_address"]
  device_name = lookup(each.value, "device_name", null)
  type        = "ipsec.1"

  tags = merge(
    { Name = "${var.name}-${each.key}" },
    local.tags,
  )
}

module "vpn_gateway" {
  source = "terraform-aws-modules/vpn-gateway/aws"
  # version = "~> 2.0"

  vpc_id         = local.vpc_id
  vpn_gateway_id = local.vgw_id

  customer_gateway_id = local.cgw_ids[0]

  # precalculated length of module variable vpc_subnet_route_table_ids
  vpc_subnet_route_table_count = length(local.private_route_table_ids)
  vpc_subnet_route_table_ids   = local.private_route_table_ids

  local_ipv4_network_cidr  = "0.0.0.0/0"
  remote_ipv4_network_cidr = local.vpc_cidr_block

  # # tunnel inside cidr & preshared keys (optional)
  # tunnel1_inside_cidr   = var.custom_tunnel1_inside_cidr
  # tunnel2_inside_cidr   = var.custom_tunnel2_inside_cidr
  # tunnel1_preshared_key = var.custom_tunnel1_preshared_key
  # tunnel2_preshared_key = var.custom_tunnel2_preshared_key
}
