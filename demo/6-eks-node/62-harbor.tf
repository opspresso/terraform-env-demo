# Harbor (argocd-env-addons charts/harbor). Harbor 2.15 publishes amd64 images
# only, and every other NodePool is arm64. The taint keeps other Pods off;
# Harbor selects kubernetes.io/arch=amd64 and tolerates the taint.
# Remove this pool when Harbor runs on arm64 images (2.16 or later).
resource "kubernetes_manifest" "harbor_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "harbor-amd64" }
    spec = {
      limits = { cpu = "8", memory = "32Gi" }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "5m"
        budgets             = [{ nodes = "1" }]
      }
      template = {
        spec = {
          nodeClassRef = { group = "eks.amazonaws.com", kind = "NodeClass", name = "default" }
          taints       = [{ key = "opspresso.com/harbor", value = "true", effect = "NoSchedule" }]
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["on-demand"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m"] },
            { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["2", "4"] },
          ]
        }
      }
    }
  }
}
