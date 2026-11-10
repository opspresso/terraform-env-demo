output "security_group_id" {
  value = aws_security_group.public.id
}

output "internal_security_group_id" {
  value = aws_security_group.internal.id
}

output "public" {
  value = aws_lb.public.dns_name
}

output "public_http_0" {
  value = aws_lb_target_group.public_http_0.arn
}

output "public_http_a" {
  value = aws_lb_target_group.public_http_a.arn
}

output "public_http_b" {
  value = aws_lb_target_group.public_http_b.arn
}

output "public_grpc_0" {
  value = aws_lb_target_group.public_grpc_0.arn
}

output "internal" {
  value = aws_lb.internal.dns_name
}

output "internal_http_0" {
  value = aws_lb_target_group.internal_http_0.arn
}

output "internal_http_a" {
  value = aws_lb_target_group.internal_http_a.arn
}

output "internal_http_b" {
  value = aws_lb_target_group.internal_http_b.arn
}
