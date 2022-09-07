# output

output "atlantis_url" {
  description = "URL of Atlantis"
  value       = module.atlantis.atlantis_url
}

# output "atlantis_url_events" {
#   description = "Webhook events URL of Atlantis"
#   value       = module.atlantis.atlantis_url_events
# }

# output "webhook_secret" {
#   description = "Webhook secret"
#   value       = module.atlantis.webhook_secret
#   # aws ssm get-parameter --name "/atlantis/webhook/secret" --with-decryption | jq .Parameter.Value -r
# }

# # ECS
# output "ecs_cluster_id" {
#   description = "ECS cluster id"
#   value       = module.atlantis.ecs_cluster_id
# }

# output "ecs_cluster_arn" {
#   description = "ECS cluster ARN"
#   value       = module.atlantis.ecs_cluster_arn
# }

# output "task_role_arn" {
#   description = "The Atlantis ECS task role arn"
#   value       = module.atlantis.task_role_arn
# }

# # ALB
# output "alb_dns_name" {
#   description = "Dns name of alb"
#   value       = module.atlantis.alb_dns_name
# }

# output "alb_zone_id" {
#   description = "Zone ID of alb"
#   value       = module.atlantis.alb_zone_id
# }

# output "alb_arn" {
#   description = "ARN of alb"
#   value       = module.atlantis.alb_arn
# }
