# # worker intra

# module "intra-v1" {
#   source = "nalbam/eks-worker/aws"
#   # version = "1.0.1"

#   name    = "intra"
#   subname = "v1"

#   cluster_info = module.eks.cluster_info

#   role_name       = local.worker_role_name
#   security_groups = local.worker_security_groups
#   subnet_ids      = local.intra_subnets

#   worker_ami_arch    = "x86_64"
#   worker_ami_keyword = "*"

#   key_name = var.key_name

#   enable_autoscale = true
#   enable_taints    = true
#   enable_spot      = true
#   enable_event     = true

#   instance_type = "c6i.large"
#   volume_type   = "gp3"
#   volume_size   = "50"

#   min = 1
#   max = 2

#   tags = local.tags
# }
