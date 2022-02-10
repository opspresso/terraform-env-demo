# # nodegroup worker

# module "graviton" {
#   source  = "nalbam/eks-nodegroup/aws"
#   version = "0.14.3"

#   name = "graviton"

#   cluster_name = local.cluster_name

#   node_role_arn   = local.worker_role_arn
#   security_groups = local.worker_security_groups
#   subnet_ids      = local.private_subnets

#   key_name = var.key_name

#   enable_taints = true
#   enable_spot   = true

#   ami_type       = "AL2_ARM_64"
#   instance_types = ["c6g.large"]

#   volume_type = "gp3"
#   volume_size = "30"

#   min = 2
#   max = 6

#   tags = local.tags
# }
