# locals self_managed_node_groups

locals {
  self_managed_node_group_defaults = {
    subnet_ids             = local.private_subnets
    vpc_security_group_ids = local.vpc_security_group_ids

    instance_type = "c6i.xlarge"

    launch_template_version = "$Latest"

    ebs_optimized     = true
    enable_monitoring = true

    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 100
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 150
          delete_on_termination = true
        }
      }
    }

    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
    }
  }

  self_managed_node_groups = {
    workers = {
      name = format("%s-workers", var.cluster_name)

      min_size = 3
      max_size = 6

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 1
          on_demand_percentage_above_base_capacity = 100
          spot_allocation_strategy                 = "price-capacity-optimized"
        }

        override = [
          {
            instance_type     = "c6i.xlarge"
            weighted_capacity = "1"
          },
          {
            instance_type     = "c7i.xlarge"
            weighted_capacity = "1"
          },
        ]
      }

      iam_role_additional_policies = {
        additional = aws_iam_policy.additional.arn
      }

      key_name = var.key_name

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=group=workers'"

      # bootstrap_extra_args = <<-EOT
      #   [settings.kubernetes.node-labels]
      #   group = "workers"
      # EOT

      tags = merge(
        local.tags,
        {
          "Name"  = format("%s-workers", var.cluster_name)
          "group" = "workers",
        },
      )
    }
  }
}

resource "aws_iam_policy" "additional" {
  name        = format("%s-additional", var.cluster_name)
  description = format("%s-additional policy", var.cluster_name)

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateTags",
          "ec2:Describe*",
          "ssm:GetParameter",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-additional", var.cluster_name)
    },
  )
}
