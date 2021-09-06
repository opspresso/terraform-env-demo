# # worker

# resource "aws_eks_node_group" "workers-v3" {
#   node_group_name = "workers-v3"

#   cluster_name = local.cluster_name

#   node_role_arn = local.worker_role_arn
#   subnet_ids    = local.subnet_ids

#   capacity_type  = "SPOT"       # ON_DEMAND, SPOT
#   ami_type       = "AL2_x86_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64
#   instance_types = ["c5.large"]

#   labels = {
#     "group"         = "workers"
#     "instancefroup" = "workers-v3"
#   }

#   # taint {
#   #   effect = "NO_SCHEDULE"
#   #   key    = "group"
#   #   value  = "workers"
#   # }

#   scaling_config {
#     desired_size = 2
#     max_size     = 6
#     min_size     = 2
#   }

#   update_config {
#     max_unavailable_percentage = 20
#   }

#   lifecycle {
#     ignore_changes = [scaling_config[0].desired_size]
#   }

#   tags = merge(
#     {
#       "Name" = "workers-v3"
#     },
#     local.tags,
#   )
# }
