# # worker intra

# module "intra-v1" {
#   source = "nalbam/eks-worker/aws"
#   version = "~> 2.3"

#   name    = "intra"
#   subname = "v1"

#   cluster_name = local.cluster_name

#   role_name       = local.worker_role_name
#   security_groups = local.worker_security_groups
#   subnet_ids      = local.intra_subnets

#   kubernetes_version = var.kubernetes_version
#   worker_ami_arch    = "x86_64"
#   worker_ami_keyword = "*"

#   key_name = var.key_name

#   enable_autoscale = true
#   enable_mixed     = true
#   enable_taints    = true

#   on_demand_base = 0
#   on_demand_rate = 0

#   mixed_instances = ["c6i.large", "c5.large"]
#   volume_type     = "gp3"
#   volume_size     = "50"

#   min = 2
#   max = 2

#   tags = local.tags

#   depends_on = [
#     module.eks,
#   ]
# }
