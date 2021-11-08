# aws_lb_target_group

resource "aws_lb_target_group" "internal_tg_0" {
  name        = format("%s-in-0", var.name)
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

resource "aws_lb_target_group" "internal_tg_a" {
  name        = format("%s-in-a", var.name)
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

resource "aws_lb_target_group" "internal_tg_b" {
  name        = format("%s-in-b", var.name)
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

output "internal_tg_0" {
  value = aws_lb_target_group.internal_tg_0.arn
}

output "internal_tg_a" {
  value = aws_lb_target_group.internal_tg_a.arn
}

output "internal_tg_b" {
  value = aws_lb_target_group.internal_tg_b.arn
}
