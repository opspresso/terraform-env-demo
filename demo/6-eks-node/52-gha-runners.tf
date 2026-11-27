# gha-runners: GitHub Actions runners (argocd-env-addons charts/arc-runners).
# Separate because runner Pods build images and start kind clusters in a privileged dind sidecar: the
# NodeClass gives Docker a large disk, and the taint keeps other Pods off.
# Nodes exist only while jobs run. Spot only: jobs wait while Spot is short. Runner Pods carry
# karpenter.sh/do-not-disrupt, so consolidation waits for the job; a Spot interruption fails the running job.

locals {
  # An 8-CPU m node (32Gi; r 64Gi) holds three runner Pods (runner + dind sidecar,
  # 2.5 CPU / 9Gi requests) after kubelet and DaemonSets. One extra node
  # permits replacement.
  gha_runners_node_limit = ceil(var.gha_runner_max_runners / 3) + 1
}

resource "kubernetes_manifest" "gha_runners_node_class" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata   = { name = "gha-runners" }
    spec = merge(local.node_class_spec, {
      networkPolicy    = "DefaultAllow"
      ephemeralStorage = { size = "${var.gha_runner_ephemeral_storage_gib}Gi", iops = 3000, throughput = 125 }
    })
  }
}

resource "kubernetes_manifest" "gha_runners_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "gha-runners" }
    spec = {
      template = {
        spec = {
          nodeClassRef = { group = "eks.amazonaws.com", kind = "NodeClass", name = kubernetes_manifest.gha_runners_node_class.manifest.metadata.name }
          taints       = [{ key = "opspresso.com/gha-runner", value = "true", effect = "NoSchedule" }]
          requirements = concat(local.node_requirements, [
            { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m", "r"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["8"] },
          ])
          expireAfter = "336h"
          # Matches the longest runner job timeout (60 minutes) plus drain time.
          terminationGracePeriod = "70m"
        }
      }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "10m"
        # Empty nodes go together after the last job; drift replaces one at a time.
        budgets = [
          { nodes = "100%", reasons = ["Empty"] },
          { nodes = "1", reasons = ["Drifted"] },
        ]
      }
      limits = { cpu = tostring(local.gha_runners_node_limit * 8), memory = "${local.gha_runners_node_limit * 64}Gi" }
    }
  }
}
