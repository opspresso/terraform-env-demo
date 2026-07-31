# aws_lb_target_group

resource "aws_lb_target_group" "public_http_0" {
  name             = format("%s-h1-0", var.name)
  port             = 80
  protocol         = "HTTP"
  # HTTP1 accepts both HTTP/1.1 and HTTP/2 clients; HTTP2 rejects HTTP/1.1 with
  # a 464 before the request ever reaches the mesh. That broke every inbound
  # webhook — Slack events, trigger deliveries, A2A — while browsers kept
  # working over h2, so it looked healthy. gRPC needs h2 end to end and has its
  # own target group below.
  protocol_version = "HTTP1" # [GRPC, HTTP1, HTTP2]
  slow_start       = 30
  target_type      = "ip"
  vpc_id           = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5

  # The listener points here, so the replacement has to overlap: create the new
  # group, move the listener, then drop the old one. Destroying first fails with
  # ResourceInUse and leaves the change half-applied.
  lifecycle {
    create_before_destroy = true
  }

  # required for EKS Auto Mode TargetGroupBinding (eks.amazonaws.com/v1)
  tags = {
    "eks:eks-cluster-name" = "eks-demo"
  }
}

resource "aws_lb_target_group" "public_http_a" {
  name             = format("%s-h1-a", var.name)
  port             = 80
  protocol         = "HTTP"
  # HTTP1 accepts both HTTP/1.1 and HTTP/2 clients; HTTP2 rejects HTTP/1.1 with
  # a 464 before the request ever reaches the mesh. That broke every inbound
  # webhook — Slack events, trigger deliveries, A2A — while browsers kept
  # working over h2, so it looked healthy. gRPC needs h2 end to end and has its
  # own target group below.
  protocol_version = "HTTP1" # [GRPC, HTTP1, HTTP2]
  slow_start       = 30
  target_type      = "ip"
  vpc_id           = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5

  # The listener points here, so the replacement has to overlap: create the new
  # group, move the listener, then drop the old one. Destroying first fails with
  # ResourceInUse and leaves the change half-applied.
  lifecycle {
    create_before_destroy = true
  }

  # required for EKS Auto Mode TargetGroupBinding (eks.amazonaws.com/v1)
  tags = {
    "eks:eks-cluster-name" = "eks-demo-a"
  }
}

resource "aws_lb_target_group" "public_http_b" {
  name             = format("%s-h1-b", var.name)
  port             = 80
  protocol         = "HTTP"
  # HTTP1 accepts both HTTP/1.1 and HTTP/2 clients; HTTP2 rejects HTTP/1.1 with
  # a 464 before the request ever reaches the mesh. That broke every inbound
  # webhook — Slack events, trigger deliveries, A2A — while browsers kept
  # working over h2, so it looked healthy. gRPC needs h2 end to end and has its
  # own target group below.
  protocol_version = "HTTP1" # [GRPC, HTTP1, HTTP2]
  slow_start       = 30
  target_type      = "ip"
  vpc_id           = local.vpc_id

  health_check {
    port    = 15021
    path    = "/healthz/ready"
    matcher = "200"
  }

  deregistration_delay = 5

  # The listener points here, so the replacement has to overlap: create the new
  # group, move the listener, then drop the old one. Destroying first fails with
  # ResourceInUse and leaves the change half-applied.
  lifecycle {
    create_before_destroy = true
  }

  # required for EKS Auto Mode TargetGroupBinding (eks.amazonaws.com/v1)
  tags = {
    "eks:eks-cluster-name" = "eks-demo-b"
  }
}

# output

output "public_http_0" {
  value = aws_lb_target_group.public_http_0.arn
}

output "public_http_a" {
  value = aws_lb_target_group.public_http_a.arn
}

output "public_http_b" {
  value = aws_lb_target_group.public_http_b.arn
}

# save ssm

resource "aws_ssm_parameter" "public_http_0" {
  name  = format("/k8s/common/%s/public_http_0", var.name)
  type  = "String"
  value = aws_lb_target_group.public_http_0.arn
}

resource "aws_ssm_parameter" "public_http_a" {
  name  = format("/k8s/common/%s/public_http_a", var.name)
  type  = "String"
  value = aws_lb_target_group.public_http_a.arn
}

resource "aws_ssm_parameter" "public_http_b" {
  name  = format("/k8s/common/%s/public_http_b", var.name)
  type  = "String"
  value = aws_lb_target_group.public_http_b.arn
}
