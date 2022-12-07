# # worker graviton

# module "graviton-v1" {
#   source = "nalbam/eks-worker/aws"
#   version = "~> 2.1"

#   name    = "graviton"
#   subname = "v1"

#   cluster_name = local.cluster_name

#   role_name       = local.worker_role_name
#   security_groups = local.worker_security_groups
#   subnet_ids      = local.private_subnets

#   kubernetes_version = var.kubernetes_version
#   worker_ami_arch    = "arm64"
#   worker_ami_keyword = "*"

#   key_name = var.key_name

#   enable_autoscale = true
#   enable_event     = true
#   enable_spot      = true
#   enable_taints    = true

#   instance_type = "c6g.large"
#   volume_type   = "gp3"
#   volume_size   = "50"

#   min = 1
#   max = 2

#   tags = local.tags
# }
