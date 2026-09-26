# output

output "instance_id" {
  description = "Session Manager 로 접속할 EC2 ID"
  value       = aws_instance.exit_node.id
}

output "public_ip" {
  description = "Exit node 사용 시 인터넷에 표시될 IPv4"
  value       = aws_instance.exit_node.public_ip
}

output "tailscale_hostname" {
  value = local.name
}

output "ssm_connect_command" {
  value = "aws ssm start-session --region ${var.region} --target ${aws_instance.exit_node.id}"
}
