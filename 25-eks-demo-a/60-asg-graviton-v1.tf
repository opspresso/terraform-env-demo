# # worker graviton

# module "graviton-v1" {
#   source  = "nalbam/eks-worker/aws"
#   version = "0.14.9"

#   name    = "graviton"
#   subname = "v1"

#   cluster_info = module.eks.cluster_info

#   role_name       = local.worker_role_name
#   security_groups = local.worker_security_groups
#   subnet_ids      = local.subnet_ids

#   worker_ami_arch    = "arm64"
#   worker_ami_keyword = "*"

#   key_name = var.key_name

#   enable_autoscale = true
#   enable_taints    = true
#   enable_spot      = true

#   instance_type = "c6g.xlarge"
#   volume_type   = "gp3"
#   volume_size   = "30"

#   min = 2
#   max = 6

#   tags = local.tags
# }
