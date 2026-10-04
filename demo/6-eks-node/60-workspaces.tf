locals {
  # A 4-CPU node has room for three 1-CPU/2Gi Pods after kubelet and DaemonSets.
  # One extra node permits replacement; the memory ceiling also fits 16Gi m nodes.
  workspace_node_limit = ceil(var.workspace_max_pods / 3) + 1
}

# Dedicated bounded capacity uses the existing Auto Mode role, subnets and CNI.
# Do not edit or replace the EKS-managed default NodeClass/NodePools.
resource "kubernetes_manifest" "workspace_node_class" {
  manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata   = { name = "workspaces" }
    spec = {
      role                       = data.terraform_remote_state.eks.outputs.workspace_node_role_name
      subnetSelectorTerms        = [for id in data.terraform_remote_state.eks.outputs.workspace_subnet_ids : { id = id }]
      securityGroupSelectorTerms = [{ id = data.terraform_remote_state.eks.outputs.workspace_security_group_id }]
      # Fail closed while the policy agent programs a newly started Sandbox Pod.
      networkPolicy          = "DefaultDeny"
      networkPolicyEventLogs = "Enabled"
      ephemeralStorage = {
        size       = "${var.workspace_ephemeral_storage_gib}Gi"
        iops       = 3000
        throughput = 125
      }
    }
  }
}

resource "kubernetes_manifest" "workspace_node_pool" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "workspaces" }
    spec = {
      limits = { cpu = tostring(local.workspace_node_limit * 4), memory = "${local.workspace_node_limit * 16}Gi" }
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "5m"
        budgets             = [{ nodes = "1" }]
      }
      template = {
        spec = {
          nodeClassRef = { group = "eks.amazonaws.com", kind = "NodeClass", name = "workspaces" }
          taints       = [{ key = "agent-studio/workspace", value = "true", effect = "NoSchedule" }]
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["on-demand"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["c", "m"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["4"] },
          ]
          expireAfter            = "336h"
          terminationGracePeriod = "10m"
        }
      }
    }
  }
  depends_on = [kubernetes_manifest.workspace_node_class]
}
