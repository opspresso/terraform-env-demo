# # nodegroup graviton

# module "graviton" {
#   source = "nalbam/eks-nodegroup/aws"
#   version = "~> 1.0"

#   name = "graviton"

#   cluster_name = local.cluster_name

#   node_role_arn   = local.worker_role_arn
#   security_groups = local.worker_security_groups
#   subnet_ids      = local.private_subnets

#   key_name = var.key_name

#   enable_spot   = true
#   enable_taints = true

#   ami_type       = "AL2_ARM_64"
#   instance_types = ["c6g.large"]

#   volume_type = "gp3"
#   volume_size = "50"

#   min = 2
#   max = 6

#   tags = local.tags

#   depends_on = [
#     module.eks,
#   ]
# }
