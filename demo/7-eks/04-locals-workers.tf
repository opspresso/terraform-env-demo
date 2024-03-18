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

    key_name = var.key_name

    iam_role_additional_policies = {
      additional = aws_iam_policy.additional.arn
    }

    pre_bootstrap_user_data = <<-EOT
      mkdir -p ~/.docker /var/lib/kubelet
      aws ssm get-parameter --name "/k8s/common/docker-config" --with-decryption --output text --query Parameter.Value > ~/.docker/config.json
      aws ssm get-parameter --name "/k8s/common/docker-config" --with-decryption --output text --query Parameter.Value > /var/lib/kubelet/config.json
      aws ssm get-parameter --name "/k8s/common/containerd-config" --with-decryption --output text --query Parameter.Value >> /etc/eks/containerd/containerd-config.toml
    EOT

    post_bootstrap_user_data = <<-EOT
      aws_region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/\(.*\)[a-z]/\1/')
      aws_instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
      aws_instance_lifecycle=$(curl -s http://169.254.169.254/latest/meta-data/instance-life-cycle)
      aws ec2 create-tags --resources $aws_instance_id --region $aws_region --tags Key=Lifecycle,Value=$aws_instance_lifecycle
      echo "All done."
    EOT
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

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=group=workers'"

      autoscaling_group_tags = {
        "k8s.io/cluster-autoscaler/enabled" : true,
        "k8s.io/cluster-autoscaler/${var.cluster_name}" : "owned",
      }

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
