# general: Spot capacity for every Pod that has no dedicated pool and that a restart does not harm
# (Argo CD, observability, GitLab, sample and Agent Runway apps, and HPA growth of the core services).
# One dynamic pool per architecture for all sizes. Karpenter picks the cheapest instance that fits the
# pending Pods, and consolidation replaces underused nodes. An Agent Runway 8xlarge Pod (16 CPU, 32Gi)
# needs a 32 vCPU node.
# - general (arm64): service images are linux/arm64.
# - general-amd64: separate architecture. Only Agent Runway app Pods that chose amd64 tolerate its taint;
#   app-deploy sets nodeSelector kubernetes.io/arch=amd64 (agent-platform docs/APP_DELIVERY.md).

locals {
  general_architectures = {
    arm64 = { name = "general", taints = [] }
    amd64 = { name = "general-amd64", taints = [{ key = "opspresso.com/arch", value = "amd64", effect = "NoSchedule" }] }
  }
}

resource "kubernetes_manifest" "general_node_class" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata   = { name = "general" }
    spec = merge(local.node_class_spec, {
      networkPolicy          = "DefaultAllow"
      networkPolicyEventLogs = "Disabled"
      snatPolicy             = "Random"
      ephemeralStorage       = { size = "80Gi", iops = 3000, throughput = 125 }
    })
  }
}

resource "kubernetes_manifest" "general_node_pool" {
  for_each = local.general_architectures

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = each.value.name }
    spec = {
      template = {
        spec = {
          nodeClassRef = { group = "eks.amazonaws.com", kind = "NodeClass", name = kubernetes_manifest.general_node_class.manifest.metadata.name }
          taints       = each.value.taints
          # The workload is memory-bound (about 0.8 vCPU and 18Gi used, 2026-11-27): r has 8Gi and m 4Gi per vCPU,
          # and r large Spot often costs less than c large (2Gi per vCPU). c is left out.
          requirements = concat(local.node_requirements, [
            { key = "kubernetes.io/arch", operator = "In", values = [each.key] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m", "r"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["2", "4", "8", "16", "32"] },
          ])
          expireAfter            = "336h"
          terminationGracePeriod = "24h"
        }
      }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "5m"
        budgets             = [{ nodes = "1" }]
      }
      # r instances have 8Gi per vCPU.
      limits = { cpu = tostring(var.general_max_cpu[each.key]), memory = "${var.general_max_cpu[each.key] * 8}Gi" }
    }
  }
}
