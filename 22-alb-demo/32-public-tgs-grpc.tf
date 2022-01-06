# aws_lb_target_group

resource "aws_lb_target_group" "public_grpc_0" {
  name             = format("%s-grpc-0", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "GRPC"
  target_type      = "ip"
  vpc_id           = local.vpc_id
}

resource "aws_lb_target_group" "public_grpc_a" {
  name             = format("%s-grpc-a", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "GRPC"
  target_type      = "ip"
  vpc_id           = local.vpc_id
}

resource "aws_lb_target_group" "public_grpc_b" {
  name             = format("%s-grpc-b", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "GRPC"
  target_type      = "ip"
  vpc_id           = local.vpc_id
}

# output

output "public_grpc_0" {
  value = aws_lb_target_group.public_grpc_0.arn
}

output "public_grpc_a" {
  value = aws_lb_target_group.public_grpc_a.arn
}

output "public_grpc_b" {
  value = aws_lb_target_group.public_grpc_b.arn
}
