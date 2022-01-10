# # aws_lb_listener

# resource "aws_lb_listener" "internal_grpc" {
#   load_balancer_arn = aws_lb.internal.arn

#   port            = "50051"
#   protocol        = "HTTPS"
#   ssl_policy      = "ELBSecurityPolicy-2016-08"
#   certificate_arn = data.aws_acm_certificate.internal_grpc[0].arn

#   default_action {
#     type = "forward"

#     forward {
#       dynamic "target_group" {
#         for_each = local.tgs
#         content {
#           arn    = target_group.value.internal_http2
#           weight = target_group.value.weight
#         }
#       }

#       stickiness {
#         enabled  = false
#         duration = 600
#       }
#     }
#   }
# }

# resource "aws_lb_listener_rule" "internal_grpc--a" {
#   listener_arn = aws_lb_listener.internal_grpc.arn
#   priority     = 11

#   condition {
#     host_header {
#       values = ["*.demo-a.nalbam.com"]
#     }
#   }

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.internal_http2_a.arn
#   }
# }

# resource "aws_lb_listener_rule" "internal_grpc--b" {
#   listener_arn = aws_lb_listener.internal_grpc.arn
#   priority     = 12

#   condition {
#     host_header {
#       values = ["*.demo-b.nalbam.com"]
#     }
#   }

#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.internal_http2_b.arn
#   }
# }

# # acm

# data "aws_acm_certificate" "internal_grpc" {
#   count = length(var.domains)

#   domain      = var.domains[count.index]
#   types       = ["AMAZON_ISSUED"]
#   most_recent = true
# }

# resource "aws_lb_listener_certificate" "internal_grpc" {
#   count = length(var.domains) > 1 ? length(var.domains) - 1 : 0

#   listener_arn    = aws_lb_listener.internal_grpc.arn
#   certificate_arn = data.aws_acm_certificate.internal_grpc[count.index + 1].arn
# }
