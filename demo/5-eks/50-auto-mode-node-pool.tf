# EKS Auto Mode baseline capacity
# 이 pool은 항상 2개를 유지하고, workload 증가분은 기존 dynamic NodePool이 처리합니다.
# compute_config의 general-purpose/system NodePool은 workload 수요에 따라 추가 확장됩니다.

resource "kubernetes_manifest" "auto_mode_baseline_node_pool" {
  depends_on = [module.eks]

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      name = "baseline"
    }

    spec = {
      replicas = var.auto_mode_baseline_replicas

      template = {
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }

          requirements = [
            {
              key      = "karpenter.sh/capacity-type"
              operator = "In"
              values   = ["on-demand"]
            },
            {
              key      = "eks.amazonaws.com/instance-category"
              operator = "In"
              values   = ["c"]
            },
            {
              key      = "eks.amazonaws.com/instance-cpu"
              operator = "Gt"
              values   = ["2"]
            }
          ]
        }
      }

      # AMI drift나 노드 교체 중 임시 여유 용량을 허용합니다.
      limits = {
        nodes = var.auto_mode_baseline_replicas + 1
      }
    }
  }
}
