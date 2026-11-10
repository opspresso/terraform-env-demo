# On-demand capacity for the shared Agent PostgreSQL (argocd-env-apps charts/postgresql, namespace
# agent-studio). Every other custom NodePool is Spot. A Spot reclaim stops the database that every Agent service
# shares, so open connections end with admin_shutdown and running work such as memory dreaming stops.
# The taint keeps other Pods off; only the PostgreSQL Pod tolerates it. The EBS volume pins the Pod to its
# AZ, so the pool allows every baseline zone and Karpenter launches the node in the volume's zone.
# Auto Mode launches only instances with more than 1 vCPU, so one large node (2 vCPU, 8Gi) holds the Pod
# (requests 50m·768Mi, limit 2Gi) and the DaemonSets.
resource "kubernetes_manifest" "agent_database_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "agent-database" }
    spec = {
      # One node plus one for replacement during drift or expiry.
      limits = { cpu = "4", memory = "16Gi" }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "10m"
        budgets             = [{ nodes = "1" }]
      }
      template = {
        spec = {
          nodeClassRef = { group = "eks.amazonaws.com", kind = "NodeClass", name = "default" }
          taints       = [{ key = "opspresso.com/agent-database", value = "true", effect = "NoSchedule" }]
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["on-demand"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m"] },
            { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["2"] },
            { key = "topology.kubernetes.io/zone", operator = "In", values = var.baseline_zones },
          ]
        }
      }
    }
  }
}
