locals {
  # An 8-CPU m node (32Gi) holds two runner Pods (runner + dind sidecar,
  # 3.5 CPU / 14Gi requests) after kubelet and DaemonSets. One extra node
  # permits replacement.
  gha_runner_node_limit = ceil(var.gha_runner_max_runners / 2) + 1
}

# GitHub Actions runners (argocd-env-addons charts/arc-runners). Runner Pods
# build images and start kind clusters in a privileged dind sidecar, so the
# class allows network egress by default and gives Docker a large disk.
resource "kubernetes_manifest" "gha_runner_node_class" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata   = { name = "gha-runners" }
    spec = {
      role                       = data.terraform_remote_state.eks.outputs.workspace_node_role_name
      subnetSelectorTerms        = [for id in data.terraform_remote_state.eks.outputs.workspace_subnet_ids : { id = id }]
      securityGroupSelectorTerms = [{ id = data.terraform_remote_state.eks.outputs.workspace_security_group_id }]
      networkPolicy              = "DefaultAllow"
      ephemeralStorage = {
        size       = "${var.gha_runner_ephemeral_storage_gib}Gi"
        iops       = 3000
        throughput = 125
      }
    }
  }
}

# Nodes exist only while jobs run: Spot first, on-demand when Spot is short.
# Runner Pods carry karpenter.sh/do-not-disrupt, so consolidation waits for
# the job; a Spot interruption fails the running job.
resource "kubernetes_manifest" "gha_runner_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "gha-runners" }
    spec = {
      limits = { cpu = tostring(local.gha_runner_node_limit * 8), memory = "${local.gha_runner_node_limit * 32}Gi" }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "10m"
        # Empty nodes go together after the last job; drift replaces one at a time.
        budgets = [
          { nodes = "100%", reasons = ["Empty"] },
          { nodes = "1", reasons = ["Drifted"] },
        ]
      }
      template = {
        spec = {
          nodeClassRef = { group = "eks.amazonaws.com", kind = "NodeClass", name = "gha-runners" }
          taints       = [{ key = "opspresso.com/gha-runner", value = "true", effect = "NoSchedule" }]
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot", "on-demand"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m"] },
            { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["8"] },
          ]
          expireAfter = "336h"
          # Matches the longest runner job timeout (60 minutes) plus drain time.
          terminationGracePeriod = "70m"
        }
      }
    }
  }
  depends_on = [kubernetes_manifest.gha_runner_node_class]
}
