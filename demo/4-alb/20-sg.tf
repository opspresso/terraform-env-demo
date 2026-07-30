# aws_security_group

resource "aws_security_group" "public" {
  name = var.name

  description = format("controls access to the public ALB for %s", var.name)

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

  tags = {
    Name = var.name
  }
}

# internal ALB 는 VPC 내부에서만 접근합니다.
# public SG 를 재사용하면 0.0.0.0/0 이 그대로 적용되므로 별도 SG 로 분리합니다.
# internal listener 는 80 만 사용하므로 443 은 열지 않습니다.

resource "aws_security_group" "internal" {
  name = format("%s-in", var.name)

  description = format("controls access to the internal ALB for %s", var.name)

  vpc_id = local.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "80"
    to_port     = "80"
    cidr_blocks = [local.vpc_cidr]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = format("%s-in", var.name)
  }
}

# output

output "security_group_id" {
  value = aws_security_group.public.id
}

output "internal_security_group_id" {
  value = aws_security_group.internal.id
}
