# k3s 노드 — 기존에 생성된 EC2를 Terraform으로 가져와 관리한다.

data "aws_iam_instance_profile" "k3s" {
  name = "dockpad-agent-studio-profile"
}

data "aws_route53_zone" "k3s" {
  name         = "opsp.dev"
  private_zone = false
}

resource "aws_instance" "k3s" {
  ami                         = "ami-07eb6efe2dab82ae4"
  instance_type               = "c6i.xlarge"
  subnet_id                   = "subnet-06b0a3ca13327ae30"
  vpc_security_group_ids      = ["sg-014d7e010d702add6"]
  iam_instance_profile        = data.aws_iam_instance_profile.k3s.name
  key_name                    = "nalbam-bruce"
  ebs_optimized               = true
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 80
    iops                  = 3000
    throughput            = 125
    encrypted             = false
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name = "k3s-demo"
  }

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = aws_instance.k3s
  id = "i-08e4a94565495548d"
}

resource "aws_route53_record" "k3s_wildcard" {
  zone_id = data.aws_route53_zone.k3s.zone_id
  name    = "*.demo.opsp.dev"
  type    = "A"
  ttl     = 300
  records = [aws_instance.k3s.public_ip]
}

import {
  to = aws_route53_record.k3s_wildcard
  id = "Z04116161MQCAA7BJ31AV_*.demo.opsp.dev._A"
}

# IDC 사용자에 붙어 있던 애플리케이션 권한을 k3s 노드 역할로 옮긴다.
resource "aws_iam_role_policy_attachment" "k3s_shared" {
  for_each = toset([
    "pod-role--agent-studio",
    "pod-role--mcp-cloudwatch",
    "pod-role--mcp-memory",
    "pod-role--external-secrets",
  ])

  role       = data.aws_iam_instance_profile.k3s.role_name
  policy_arn = format("arn:aws:iam::%s:policy/%s", local.account_id, each.value)
}

resource "aws_iam_role_policy_attachment" "k3s_ecr_pull" {
  role       = data.aws_iam_instance_profile.k3s.role_name
  policy_arn = aws_iam_policy.idc_ecr_pull.arn
}

resource "aws_iam_role_policy_attachment" "k3s_ssm_read" {
  role       = data.aws_iam_instance_profile.k3s.role_name
  policy_arn = aws_iam_policy.idc_ssm_read.arn
}
