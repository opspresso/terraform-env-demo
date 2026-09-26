# exit node

resource "aws_instance" "exit_node" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t4g.nano"
  subnet_id                   = data.aws_subnet.default.id
  vpc_security_group_ids      = [aws_security_group.exit_node.id]
  iam_instance_profile        = aws_iam_instance_profile.exit_node.name
  key_name                    = "nalbam-bruce"
  associate_public_ip_address = true
  source_dest_check           = false

  user_data                   = file("${path.module}/bootstrap-tailscale-exit.sh")
  user_data_replace_on_change = true

  # CPU credit 초과 과금 없이 최소 인스턴스로 운영합니다.
  credit_specification {
    cpu_credits = "standard"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name = local.name
  }

  # AMI 업데이트만으로는 노드를 교체하지 않아 Tailscale 등록을 유지합니다.
  lifecycle {
    ignore_changes = [ami]
  }

  # 최초 부팅 전에 SSM 권한이 준비되어야 합니다.
  depends_on = [aws_iam_role_policy_attachment.ssm_core]
}
