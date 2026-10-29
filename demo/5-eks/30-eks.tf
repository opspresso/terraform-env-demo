# eks
# https://github.com/terraform-aws-modules/terraform-aws-eks

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name = var.name

  kubernetes_version = var.kubernetes_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  ip_family = var.ip_family
  # Alloy·Forge NetworkPolicy가 DNS(172.20.0.10)·API(172.20.0.1) Service IP를 고정값으로 사용합니다.
  service_ipv4_cidr          = "172.20.0.0/16"
  create_cni_ipv6_iam_policy = var.ip_family == "ipv6" ? true : false

  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  enable_cluster_creator_admin_permissions = true

  # EKS Auto Mode. 앱 용량을 Graviton(arm64)으로 고정하려고 내장 general-purpose pool을 켜지 않습니다.
  # 앱 용량은 6-eks-node의 baseline·general NodePool이 제공합니다.
  compute_config = {
    enabled    = true
    node_pools = ["system"]
  }

  access_entries = local.access_entries

  # 공통 태그는 provider default_tags 로 적용됩니다. 여기에 Name 을 넣으면
  # 모듈이 계산한 Name(예: eks-demo-eks-irsa)을 덮어씁니다.
}
