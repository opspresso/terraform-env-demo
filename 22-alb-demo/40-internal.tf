# aws_lb

resource "aws_lb" "internal" {
  name = format("%s-in", var.name)

  internal           = true
  load_balancer_type = "application"
  subnets            = local.private_subnets
  security_groups    = local.security_groups

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false
  enable_http2                     = true

  # access_logs {
  #   bucket  = aws_s3_bucket.logs.bucket
  #   prefix  = var.name
  #   enabled = true
  # }

  tags = local.tags
}

# output

output "internal" {
  value = aws_lb.internal.dns_name
}
