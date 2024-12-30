# locals self_managed_node_groups

locals {
  self_managed_node_group_defaults = {
    subnet_ids             = local.private_subnets
    vpc_security_group_ids = local.vpc_security_group_ids

    ami_type      = "AL2023_x86_64_STANDARD"
    instance_type = "c6i.xlarge"

    launch_template_version = "$Latest"

    min_size = 3
    max_size = 12

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

    # This is not required - demonstrates how to pass additional configuration to nodeadm
    # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
    cloudinit_pre_nodeadm = [
      {
        content_type = "application/node.eks.aws"
        content      = <<-EOT
          ---
          apiVersion: node.eks.aws/v1alpha1
          kind: NodeConfig
          spec:
            kubelet:
              config:
                shutdownGracePeriod: 300s
                featureGates:
                  DisableKubeletCloudCredentialProviders: true
        EOT
      },
    ]
  }

  self_managed_node_groups = {
    workers = {
      name = format("%s-workers", var.cluster_name)

      min_size = 3
      max_size = 12

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
