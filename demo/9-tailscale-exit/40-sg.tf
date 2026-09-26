# security group

resource "aws_security_group" "exit_node" {
  name        = "${local.name}-sg"
  description = "Tailscale direct connections"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Tailscale WireGuard"
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-sg"
  }
}
