# Session Manager 관리 권한

resource "aws_iam_role" "exit_node" {
  name        = "${local.name}-role"
  description = "IAM role for the Tailscale exit node"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${local.name}-role"
  }
}

resource "aws_iam_instance_profile" "exit_node" {
  name = "${local.name}-profile"
  role = aws_iam_role.exit_node.name

  tags = {
    Name = "${local.name}-profile"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.exit_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
