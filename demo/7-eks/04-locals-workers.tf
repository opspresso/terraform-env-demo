# locals self_managed_node_groups

locals {
  node_groups = {
    workers = {
      group = "workers"
    }
  }

  self_managed_node_groups_bolck = {
    for key, value in local.node_groups : key => [
      {
        device_name = try(value["device_name"], "/dev/xvda")
        ebs = {
          delete_on_termination = try(value["delete_on_termination"], "true")
          volume_size           = try(value["volume_size"], 100)
          volume_type           = try(value["volume_type"], "gp3")
        }
      },
    ]
  }

  self_managed_node_groups_cloudinit_pre = {
    for key, value in local.node_groups : key => [
      {
        content_type = "text/x-shellscript"
        content      = <<-EOT
          #!/bin/bash -xe

          echo "TMOUT=600" >> /etc/profile

          aws ssm get-parameter --name "/k8s/common/containerd-config" --with-decryption \
            --output text --query Parameter.Value >> /etc/containerd/config.toml

          ${try(value["cloudinit_pre"], "")}

        EOT
      },
    ]
  }

  self_managed_node_groups_labels = {
    for key, value in local.node_groups : key => {
      "eks.amazonaws.com/nodegroup" = key
      "group"                       = key
    }
  }

  self_managed_node_groups_taints = {
    for key, value in local.node_groups : key => {
      "args" = value["group"] == "workers" ? "" : format("- --register-with-taints=group=%s:NoSchedule", value["group"])
    }
  }

  self_managed_node_groups_extra_args = {
    for key, value in local.node_groups : key => {
      "args" = try(format("- %s", value["extra_args"]), "")
    }
  }

  self_managed_node_groups_cloudinit_post = {
    for key, value in local.self_managed_node_groups_labels : key => [
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
              flags:
                - --node-labels=${replace(replace(jsonencode(value), "/[\\{\\}\"\\s]/", ""), ":", "=")}
                ${local.self_managed_node_groups_taints[key].args}
                ${local.self_managed_node_groups_extra_args[key].args}
        EOT
      },
      {
        content_type = "text/x-shellscript"
        content      = <<-EOT
          #!/bin/bash -xe

          ${try(local.node_groups[key].cloudinit_post, "")}

          echo "Hello, ${var.cluster_name} ${key}!"

        EOT
      },
    ]
  }

  self_managed_node_groups_tags = {
    for key, value in local.node_groups : key => merge(
      local.tags,
      {
        "Name"                = format("%s-%s", var.cluster_name, key)
        "KubernetesNodeGroup" = format("%s-%s", var.cluster_name, value.group)
      },
      try(value["enable_autoscale"], true) ? {
        "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
        "k8s.io/cluster-autoscaler/enabled"             = "true"
      } : {},
      try(value["enable_event"], true) ? {
        "aws-node-termination-handler/${var.cluster_name}" = "owned"
        "aws-node-termination-handler/managed"             = "true"
      } : {},
      try(value["tags"], {}),
    )
  }

  self_managed_node_groups = {
    for key, value in local.node_groups : key => {
      ami_type      = try(value["ami_type"], "AL2023_x86_64_STANDARD")
      instance_type = try(value["instance_type"], "c6i.large")

      min_size     = try(value["min"], 3)
      max_size     = try(value["max"], 12)
      desired_size = try(value["desired_size"], 3)

      launch_template_version = try(value["launch_template_version"], "$Latest")

      cloudinit_pre_nodeadm  = local.self_managed_node_groups_cloudinit_pre[key]
      cloudinit_post_nodeadm = local.self_managed_node_groups_cloudinit_post[key]

      tags = local.self_managed_node_groups_tags[key]
    }
  }
}
