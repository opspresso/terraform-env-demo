# On-demand capacity for the services a restart interrupts: the shared Agent PostgreSQL, sign-in (LLDAP, Dex), the
# Istio ingress path and the Agent services. Everything else runs on the Spot baseline and general NodePools.
# A Spot reclaim gives two minutes of notice and often takes several nodes of one AZ at once, so these services move
# off Spot instead of relying on more Spot replicas.
#
# One static node per AZ, like baseline: a static NodePool does not spread its nodes across AZs. The EBS volumes of
# the single-replica services (PostgreSQL, LLDAP) are in ap-northeast-2c, so those Pods land on core-2c.
# Pods opt in with the `opspresso.com/tier=core` toleration and node affinity: required for single-replica stateful
# services, preferred for replicated ones so HPA growth and rollout surge spill over to Spot instead of waiting.
# Requests on core are about 0.8 vCPU and 6.1Gi including DaemonSets (2026-11-11), so two large m nodes
# (1780m, 7.0Gi allocatable each) keep room for HPA growth.
resource "kubernetes_manifest" "core_zone" {
  for_each = toset(var.baseline_zones)

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      # ap-northeast-2a -> core-2a
      name = "core-${element(split("-", each.key), length(split("-", each.key)) - 1)}"
    }

    spec = {
      replicas = 1

      template = {
        metadata = {
          labels = { "opspresso.com/tier" = "core" }
        }
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }
          taints = [{ key = "opspresso.com/tier", value = "core", effect = "NoSchedule" }]

          # m7g.large is the cheapest match; m8g.large on-demand costs about 10% more in ap-northeast-2.
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["on-demand"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m"] },
            { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["2"] },
            { key = "topology.kubernetes.io/zone", operator = "In", values = [each.key] },
          ]
        }
      }

      # Drift replaces a core node only from 03:00 to 05:00 KST (18:00-20:00 UTC), so an AMI update restarts the
      # database during the maintenance window. Node expiry is forceful and not limited by budgets.
      # A static NodePool is never consolidated.
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "Never"
        budgets = [
          { nodes = "0", reasons = ["Drifted"], schedule = "0 20 * * *", duration = "22h" },
          { nodes = "1" },
        ]
      }

      # One replacement node during drift or expiry.
      limits = {
        nodes = 2
      }
    }
  }
}
