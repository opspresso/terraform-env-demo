# EKS Auto Mode baseline capacity
# 기준 노드 수를 유지하고 workload 증가분은 기본 dynamic NodePool이 처리합니다.
# plan 시점에 EKS API가 필요하므로 5-eks를 먼저 적용합니다.

resource "kubernetes_manifest" "baseline" {
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
              key      = "kubernetes.io/arch"
              operator = "In"
              values   = ["amd64"]
            },
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
        nodes = var.auto_mode_baseline_replicas + 2
      }
    }
  }
}
