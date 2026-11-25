resource "aws_lb_target_group" "internal_http_0" {
  name        = format("%s-in-http-0", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  slow_start  = 30
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5

  # required for EKS Auto Mode TargetGroupBinding (eks.amazonaws.com/v1)
  tags = {
    "eks:eks-cluster-name" = "eks-demo"
  }
}

resource "aws_lb_target_group" "internal_http_a" {
  name        = format("%s-in-http-a", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  slow_start  = 30
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5

  # required for EKS Auto Mode TargetGroupBinding (eks.amazonaws.com/v1)
  tags = {
    "eks:eks-cluster-name" = "eks-demo-a"
  }
}

resource "aws_lb_target_group" "internal_http_b" {
  name        = format("%s-in-http-b", var.name)
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  slow_start  = 30
  vpc_id      = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5

  # required for EKS Auto Mode TargetGroupBinding (eks.amazonaws.com/v1)
  tags = {
    "eks:eks-cluster-name" = "eks-demo-b"
  }
}
