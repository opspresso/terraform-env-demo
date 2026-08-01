# aws_lb

resource "aws_lb" "public" {
  name = var.name

  internal           = false
  load_balancer_type = "application"
  subnets            = local.public_subnets
  security_groups    = local.public_security_groups

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false
  enable_http2                     = true

  # SSE runs stream keepalives every 15s, but non-streaming runs (image predict,
  # A2A message/send) send nothing until the run finishes — up to the app's
  # 600s run deadline. The idle timeout must outlive that, not the default 60s.
  idle_timeout = 600

  # access_logs {
  #   bucket  = aws_s3_bucket.logs.bucket
  #   prefix  = var.name
  #   enabled = true
  # }

  tags = {
    Name = var.name
  }
}

# output

output "public" {
  value = aws_lb.public.dns_name
}
