# # worker workers

# module "workers" {
#   source = "terraform-aws-modules/eks/aws//modules/self-managed-node-group"
#   # version = "~> 18.0"

#   name = "workers"

#   cluster_name        = module.eks.cluster_id
#   cluster_version     = module.eks.cluster_version
#   cluster_endpoint    = module.eks.cluster_endpoint
#   cluster_auth_base64 = module.eks.cluster_certificate_authority_data

#   instance_type = "c6i.large"

#   vpc_id     = local.vpc_id
#   subnet_ids = local.private_subnets

#   vpc_security_group_ids = [
#     module.eks.cluster_primary_security_group_id,
#     module.eks.cluster_security_group_id,
#   ]

#   key_name = var.key_name

#   use_default_tags = true

#   tags = merge(local.tags, { Separate = "self-managed-node-group" })
# }
