# data

data "aws_caller_identity" "current" {
}

data "aws_subnets" "a" {
  # vpc_id = local.vpc_id
  filter {
    name   = format("tag:kubernetes.io/cluster/%s", var.cluster_name)
    values = ["shared"]
  }
  filter {
    name   = "tag:Name"
    values = [format("*-private-%s%s", var.region, "a")]
  }
}

data "aws_subnets" "b" {
  # vpc_id = local.vpc_id
  filter {
    name   = format("tag:kubernetes.io/cluster/%s", var.cluster_name)
    values = ["shared"]
  }
  filter {
    name   = "tag:Name"
    values = [format("*-private-%s%s", var.region, "b")]
  }
}

data "aws_subnets" "c" {
  # vpc_id = local.vpc_id
  filter {
    name   = format("tag:kubernetes.io/cluster/%s", var.cluster_name)
    values = ["shared"]
  }
  filter {
    name   = "tag:Name"
    values = [format("*-private-%s%s", var.region, "c")]
  }
}
