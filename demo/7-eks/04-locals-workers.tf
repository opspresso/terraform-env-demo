# locals self_managed_node_groups

locals {
  self_managed_node_group_defaults = {
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${local.cluster_name}" : "owned",
    }
  }

  self_managed_node_groups = {
    # Default node group - as provisioned by the module defaults
    default_node_group = {}

    workers = {
      name = "workers"

      min_size     = 1
      max_size     = 5
      desired_size = 2

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 20
          spot_allocation_strategy                 = "price-capacity-optimized"
        }

        override = [
          {
            instance_type     = "c6i.large"
            weighted_capacity = "2"
          },
          {
            instance_type     = "c7i.large"
            weighted_capacity = "2"
          },
        ]
      }
    }

    # Complete
    complete = {
      name            = "complete-self-mng"
      use_name_prefix = false

      subnet_ids = local.private_subnets

      min_size     = 1
      max_size     = 7
      desired_size = 1

      ami_id = data.aws_ami.eks_default.id

      pre_bootstrap_user_data = <<-EOT
        export FOO=bar
      EOT

      post_bootstrap_user_data = <<-EOT
        echo "you are free little kubelet!"
      EOT

      instance_type = "m6i.large"

      launch_template_name            = "self-managed-ex"
      launch_template_use_name_prefix = true
      launch_template_description     = "Self managed node group example launch template"

      ebs_optimized     = true
      enable_monitoring = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 75
            volume_type = "gp3"
            iops        = 3000
            throughput  = 150
            # encrypted             = true
            # kms_key_id            = module.ebs_kms_key.key_arn
            delete_on_termination = true
          }
        }
      }

      instance_attributes = {
        name = "instance-attributes"

        min_size     = 1
        max_size     = 2
        desired_size = 1

        bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

        instance_type = null

        # launch template configuration
        instance_requirements = {
          cpu_manufacturers                           = ["intel"]
          instance_generations                        = ["current", "previous"]
          spot_max_price_percentage_over_lowest_price = 100

          vcpu_count = {
            min = 1
          }

          allowed_instance_types = ["t*", "m*"]
        }

        use_mixed_instances_policy = true
        mixed_instances_policy = {
          instances_distribution = {
            on_demand_base_capacity                  = 0
            on_demand_percentage_above_base_capacity = 0
            on_demand_allocation_strategy            = "lowest-price"
            spot_allocation_strategy                 = "price-capacity-optimized"
          }

          # ASG configuration
          override = [
            {
              instance_requirements = {
                cpu_manufacturers                           = ["intel"]
                instance_generations                        = ["current", "previous"]
                spot_max_price_percentage_over_lowest_price = 100

                vcpu_count = {
                  min = 1
                }

                allowed_instance_types = ["t*", "m*"]
              }
            }
          ]
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true
      iam_role_name            = "self-managed-node-group-complete-example"
      iam_role_use_name_prefix = false
      iam_role_description     = "Self managed node group complete example role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = {
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
        additional                         = aws_iam_policy.additional.arn
      }

      tags = {
        ExtraTag = "Self managed node group complete example"
      }
    }

    # efa = {
    #   # Disabling automatic creation due to instance type/quota availability
    #   # Can be enabled when appropriate for testing/validation
    #   create = false

    #   instance_type = "trn1n.32xlarge"

    #   enable_efa_support      = true
    #   pre_bootstrap_user_data = <<-EOT
    #     # Mount NVME instance store volumes since they are typically
    #     # available on instances that support EFA
    #     setup-local-disks raid0
    #   EOT

    #   min_size     = 2
    #   max_size     = 2
    #   desired_size = 2
    # }
  }
}

data "aws_ami" "eks_default" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }
}

resource "aws_iam_policy" "additional" {
  name        = "${local.cluster_name}-additional"
  description = "Example usage of node additional policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:Describe*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = local.tags
}
