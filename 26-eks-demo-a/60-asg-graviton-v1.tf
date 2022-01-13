# # worker graviton

# module "graviton-v1" {
#   source  = "nalbam/eks-worker/aws"
#   version = "0.14.12"

#   name    = "graviton"
#   subname = "v1"

#   cluster_info = module.eks.cluster_info

#   role_name       = local.worker_role_name
#   security_groups = local.worker_security_groups
#   subnet_ids      = local.subnet_ids

#   worker_ami_arch    = "arm64"
#   worker_ami_keyword = "*"

#   key_name = var.key_name

#   enable_autoscale = false
#   enable_taints    = true
#   enable_spot      = false
#   enable_event     = true

#   instance_type = "c6g.large"
#   volume_type   = "gp3"
#   volume_size   = "30"

#   min = 1
#   max = 1

#   tags = local.tags
# }
