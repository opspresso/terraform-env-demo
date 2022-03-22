# output

output "cgw_ids" {
  description = "List of IDs of Customer Gateway"
  value       = local.cgw_ids
}

output "vpn_connection_id" {
  description = "VPN id"
  value       = module.vpn_gateway.vpn_connection_id
}
