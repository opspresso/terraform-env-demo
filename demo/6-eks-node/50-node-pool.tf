# EKS Auto Mode capacity on Graviton (arm64)
# baseline은 AZ마다 기준 노드 수를 고정하고, 증가분은 같은 조건의 dynamic `general` NodePool이 처리합니다.
# 정적 NodePool은 노드를 AZ에 분산하지 않으므로 AZ별 NodePool을 둡니다. 한 AZ가 장애 나도 다른 AZ의 노드가 남습니다.
# 5-eks는 내장 general-purpose pool을 켜지 않으므로 앱 Pod는 이 arm64 노드에서만 실행됩니다.
# plan 시점에 EKS API가 필요하므로 5-eks를 먼저 적용합니다.

locals {
  # m7g·m8g 이상 Graviton 범용 인스턴스.
  graviton_requirements = [
    { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
    { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
    { key = "karpenter.sh/capacity-type", operator = "In", values = ["on-demand"] },
    { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m"] },
    { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
  ]
}

resource "kubernetes_manifest" "baseline_zone" {
  for_each = toset(var.baseline_zones)

  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      # ap-northeast-2a -> baseline-2a
      name = "baseline-${element(split("-", each.key), length(split("-", each.key)) - 1)}"
    }

    spec = {
      replicas = var.auto_mode_baseline_replicas_per_zone

      template = {
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }

          # 고정 용량을 계산할 수 있도록 4 vCPU·16Gi(xlarge)로 고정합니다.
          requirements = concat(local.graviton_requirements, [
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["4"] },
            { key = "topology.kubernetes.io/zone", operator = "In", values = [each.key] },
          ])
        }
      }

      # AMI drift나 노드 교체 중 임시 여유 용량을 허용합니다.
      limits = {
        nodes = var.auto_mode_baseline_replicas_per_zone + 1
      }
    }
  }
}

# baseline을 넘는 requests와 rollout surge를 수용합니다. 비면 노드를 회수합니다.
resource "kubernetes_manifest" "general" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      name = "general"
    }

    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }

          requirements = concat(local.graviton_requirements, [
            { key = "eks.amazonaws.com/instance-cpu", operator = "Gt", values = ["2"] },
          ])
        }
      }

      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "5m"
        budgets             = [{ nodes = "1" }]
      }

      limits = {
        cpu    = tostring(var.general_max_cpu)
        memory = "${var.general_max_cpu * 4}Gi"
      }
    }
  }
}
