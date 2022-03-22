# efs

module "efs" {
  source  = "nalbam/efs/aws"
  # version = "0.14.2"

  name = var.name

  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids

  security_groups = local.security_groups
}
