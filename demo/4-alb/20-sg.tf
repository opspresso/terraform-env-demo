# aws_security_group

resource "aws_security_group" "public" {
  name = var.name

  description = format("controls access to the ALB for %s", var.name)

  vpc_id = local.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = "80"
    to_port          = "80"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = "443"
    to_port          = "443"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = local.tags
}

# output

output "security_group_id" {
  value = aws_security_group.public.id
}
