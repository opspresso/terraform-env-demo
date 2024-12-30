# eks
# https://github.com/terraform-aws-modules/terraform-aws-eks

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  # ipv6
  cluster_ip_family          = var.ip_family
  create_cni_ipv6_iam_policy = var.ip_family == "ipv6" ? true : false

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  # EKS Auto Mode
  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  tags = local.tags
}
