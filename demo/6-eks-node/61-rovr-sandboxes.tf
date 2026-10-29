locals {
  # An 8-CPU m node (32Gi) holds three 2-CPU/4Gi rovr sandboxes after kubelet
  # and DaemonSets. One extra node permits replacement.
  rovr_sandbox_node_limit = ceil(var.rovr_sandbox_max_pods / 3) + 1
}

# rovr sub-agent runs (argocd-env-apps charts/rovr). The pool reuses the
# workspaces NodeClass: same node role, subnets, default-deny network policy
# and encrypted ephemeral disk. Only rovr tolerates the taint.
resource "kubernetes_manifest" "rovr_sandbox_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "rovr-sandboxes" }
    spec = {
      limits = { cpu = tostring(local.rovr_sandbox_node_limit * 8), memory = "${local.rovr_sandbox_node_limit * 32}Gi" }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "5m"
        budgets             = [{ nodes = "1" }]
      }
      template = {
        spec = {
          nodeClassRef = { group = "eks.amazonaws.com", kind = "NodeClass", name = "workspaces" }
          taints       = [{ key = "rovr.dev/sandbox", value = "true", effect = "NoSchedule" }]
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["on-demand"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m"] },
            { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["8"] },
          ]
          expireAfter = "336h"
          # Sandbox Pods are karpenter.sh/do-not-disrupt; a drain waits for a
          # run up to rovr's 90-minute sandbox deadline.
          terminationGracePeriod = "90m"
        }
      }
    }
  }
  depends_on = [kubernetes_manifest.workspace_node_class]
}
