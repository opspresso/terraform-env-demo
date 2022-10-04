# # nodegroup workers

# module "workers" {
#   source = "nalbam/eks-nodegroup/aws"
#   # version = "1.0.1"

#   name = "workers"

#   cluster_name = local.cluster_name

#   node_role_arn   = local.worker_role_arn
#   security_groups = local.worker_security_groups
#   subnet_ids      = local.private_subnets

#   key_name = var.key_name

#   enable_spot   = true
#   enable_taints = false

#   ami_type       = "AL2_x86_64"
#   instance_types = ["c6i.large"]

#   volume_type = "gp3"
#   volume_size = "50"

#   min = 2
#   max = 6

#   tags = local.tags
# }
