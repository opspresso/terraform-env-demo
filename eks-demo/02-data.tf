# data

data "aws_caller_identity" "current" {
}

# vpc-demo-private-ap-northeast-2b
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
