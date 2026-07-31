# aws_lb_target_group — gRPC
#
# gRPC needs HTTP/2 from the client all the way to the backend, and an ALB
# target group can only be one protocol version: HTTP1 accepts h1 and h2 clients
# but speaks h1 to targets, HTTP2 speaks h2 but answers 464 to every h1 client.
# One group cannot serve both, so the hosts that need h2 end to end get their
# own and everything else stays on the HTTP1 default (32-public-tgs-http.tf).
#
# HTTP2 rather than GRPC: the health check below is a plain HTTP probe against
# the mesh gateway's readiness port, and a GRPC target group expects gRPC status
# codes there instead. HTTP2 carries gRPC fine and keeps the probe honest.
#
# Only the primary cluster has one. The demo-a / demo-b clusters route by their
# own `*.demo-a.` / `*.demo-b.` host rules and run nothing that needs h2; adding
# groups for them now would be infrastructure with no caller.

resource "aws_lb_target_group" "public_grpc_0" {
  name             = format("%s-grpc-0", var.name)
  port             = 80
  protocol         = "HTTP"
  protocol_version = "HTTP2" # [GRPC, HTTP1, HTTP2]
  slow_start       = 30
  target_type      = "ip"
  vpc_id           = local.vpc_id

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

# output

output "public_grpc_0" {
  value = aws_lb_target_group.public_grpc_0.arn
}

# save ssm

resource "aws_ssm_parameter" "public_grpc_0" {
  name  = format("/k8s/common/%s/public_grpc_0", var.name)
  type  = "String"
  value = aws_lb_target_group.public_grpc_0.arn
}
