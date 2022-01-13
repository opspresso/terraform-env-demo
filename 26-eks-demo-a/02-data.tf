# data

data "aws_caller_identity" "current" {
}

data "aws_subnet_ids" "a" {
  vpc_id = local.vpc_id
  # filter {
  #   name   = format("tag:kubernetes.io/cluster/%s", local.cluster_name)
  #   values = ["shared"]
  # }
  filter {
    name   = "tag:Name"
    values = [format("*-private-%s%s", var.region, "a")]
  }
}

data "aws_subnet_ids" "b" {
  vpc_id = local.vpc_id
  # filter {
  #   name   = format("tag:kubernetes.io/cluster/%s", local.cluster_name)
  #   values = ["shared"]
  # }
  filter {
    name   = "tag:Name"
    values = [format("*-private-%s%s", var.region, "b")]
  }
}

data "aws_subnet_ids" "c" {
  vpc_id = local.vpc_id
  # filter {
  #   name   = format("tag:kubernetes.io/cluster/%s", local.cluster_name)
  #   values = ["shared"]
  # }
  filter {
    name   = "tag:Name"
    values = [format("*-private-%s%s", var.region, "c")]
  }
}
