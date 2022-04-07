# eks
# https://github.com/terraform-aws-modules/terraform-aws-eks

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  # version = "~> 18.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = local.vpc_id
  subnet_ids = local.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # IPV6
  cluster_ip_family          = "ipv6"
  create_cni_ipv6_iam_policy = true

  # cluster_addons = {
  #   coredns = {
  #     resolve_conflicts = "OVERWRITE"
  #   }
  #   kube-proxy = {}
  #   vpc-cni = {
  #     resolve_conflicts        = "OVERWRITE"
  #     service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
  #   }
  # }

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  self_managed_node_groups = {
    workers = {
      name = format("%s-workers", var.cluster_name)

      subnet_ids = local.private_subnets

      min_size     = 2
      max_size     = 5
      desired_size = 2

      bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

      use_mixed_instances_policy = true
      mixed_instances_policy = {
        instances_distribution = {
          on_demand_base_capacity                  = 0
          on_demand_percentage_above_base_capacity = 20
          spot_allocation_strategy                 = "capacity-optimized"
        }

        override = [
          {
            instance_type     = "m5.large"
            weighted_capacity = "1"
          },
          {
            instance_type     = "m6i.large"
            weighted_capacity = "2"
          },
        ]
      }

      # launch_template_name            = format("%s-workers", var.cluster_name)
      # launch_template_use_name_prefix = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            iops                  = 2000
            throughput            = 150
            delete_on_termination = true
          }
        }
      }

      # metadata_options = {
      #   http_endpoint               = "enabled"
      #   http_tokens                 = "required"
      #   http_put_response_hop_limit = 2
      #   instance_metadata_tags      = "disabled"
      # }

      # pre_bootstrap_user_data = <<-EOT
      # export CONTAINER_RUNTIME="containerd"
      # export USE_MAX_PODS=false
      # EOT

      # post_bootstrap_user_data = <<-EOT
      # echo "you are free little kubelet!"
      # EOT

      # tags = {
      #   Name = format("%s-workers", var.cluster_name)
      # }
    }
  }

  tags = local.tags
}

# tf state rm module.eks.kubernetes_config_map.aws_auth
# tf import module.eks.kubernetes_config_map.aws_auth kube-system/aws-auth
