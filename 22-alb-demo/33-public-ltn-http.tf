# aws_lb_listener

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn

  port     = "80"
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
