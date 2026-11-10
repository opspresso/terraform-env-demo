# amd64 builds of Agent Runway Releases (argocd-env-projects charts/delivery
# files/app-build.yaml). A Release that lists linux/amd64 in `platforms` builds
# that image natively here; no platform is emulated. Every other NodePool is
# arm64. The taint keeps other Pods off; only the app-build `build` step
# selects kubernetes.io/arch=amd64 and tolerates it. The pool is empty between
# builds. Spot only: a Spot reclaim fails the running Release build.
resource "kubernetes_manifest" "delivery_amd64_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "delivery-amd64" }
    spec = {
      limits = { cpu = "16", memory = "64Gi" }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "10m"
        budgets             = [{ nodes = "1" }]
      }
      template = {
        spec = {
          nodeClassRef = { group = "eks.amazonaws.com", kind = "NodeClass", name = "default" }
          taints       = [{ key = "opspresso.com/delivery-build", value = "true", effect = "NoSchedule" }]
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m", "c"] },
            { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["4", "8"] },
          ]
        }
      }
    }
  }
}
