# # nodegroup monitoring

# module "monitoring" {
#   source = "nalbam/eks-nodegroup/aws"
#   # version = "1.0.1"

#   name = "monitoring"

#   cluster_name = local.cluster_name

#   node_role_arn   = local.worker_role_arn
#   security_groups = local.worker_security_groups
#   subnet_ids      = data.aws_subnets.a.ids

#   key_name = var.key_name

#   enable_taints = true
#   enable_spot   = true

#   ami_type       = "AL2_x86_64"
#   instance_types = ["m6i.large"]

#   volume_type = "gp3"
#   volume_size = "50"

#   min = 1
#   max = 2

#   tags = local.tags
# }
