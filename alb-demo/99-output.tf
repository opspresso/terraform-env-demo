# output

output "lb_id" {
  value = module.alb.lb_id
}

output "lb_dns_name" {
  value = module.alb.lb_dns_name
}

output "target_group_arns" {
  value = module.alb.target_group_arns
}
