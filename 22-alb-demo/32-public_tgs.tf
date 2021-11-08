# aws_lb_target_group

resource "aws_lb_target_group" "public_tg_0" {
  name        = format("%s-0", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

resource "aws_lb_target_group" "public_tg_a" {
  name        = format("%s-a", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

resource "aws_lb_target_group" "public_tg_b" {
  name        = format("%s-b", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5
}

# output

output "public_tg_0" {
  value = aws_lb_target_group.public_tg_0.arn
}

output "public_tg_a" {
  value = aws_lb_target_group.public_tg_a.arn
}

output "public_tg_b" {
  value = aws_lb_target_group.public_tg_b.arn
}
