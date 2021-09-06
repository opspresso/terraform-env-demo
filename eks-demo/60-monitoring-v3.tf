# # worker

# resource "aws_eks_node_group" "monitoring-v3" {
#   node_group_name = "monitoring-v3"

#   cluster_name = local.cluster_name

#   node_role_arn = local.worker_role_arn
#   subnet_ids    = [data.aws_subnet_ids.b.ids]

#   capacity_type  = "ON_DEMAND"  # ON_DEMAND, SPOT
#   ami_type       = "AL2_ARM_64" # AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64
#   instance_types = ["c6g.large"]

#   labels = {
#     "group"         = "monitoring"
#     "instancefroup" = "monitoring-v3"
#   }

#   taint {
#     effect = "NO_SCHEDULE"
#     key    = "group"
#     value  = "monitoring"
#   }

#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   update_config {
#     max_unavailable_percentage = 20
#   }

#   lifecycle {
#     ignore_changes = [scaling_config[0].desired_size]
#   }

#   tags = merge(
#     {
#       "Name" = "monitoring-v3"
#     },
#     local.tags,
#   )
# }
