# EKS Auto Mode capacity on Graviton (arm64) Spot for workloads a restart does not harm
# Services a restart interrupts run on the on-demand core NodePools (51-core-node-pool.tf). A reclaimed node is replaced by Karpenter; a reclaimed
# baseline node leaves its AZ without a baseline node until Spot capacity returns.
# baseline은 AZ마다 기준 노드 수를 고정하고, 증가분은 같은 large 크기의 dynamic `general` NodePool이 처리합니다.
# 정적 NodePool은 노드를 AZ에 분산하지 않으므로 AZ별 NodePool을 둡니다. 한 AZ가 장애 나도 다른 AZ의 노드가 남습니다.
# 5-eks는 내장 general-purpose pool을 켜지 않으므로 앱 Pod는 이 arm64 노드에서 실행됩니다.
# amd64 이미지를 고른 Agent Runway 앱 Pod만 taint를 허용해 dynamic `general-amd64` NodePool에서 실행됩니다.
# plan 시점에 EKS API가 필요하므로 5-eks를 먼저 적용합니다.

locals {
  # 7세대 이상 Graviton Spot 인스턴스.
  graviton_spot_requirements = [
    { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
    { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
    { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
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

          # 고정 용량을 계산할 수 있도록 r large(2 vCPU·16Gi)로 고정합니다. 이 workload는 메모리가 노드 수를
          # 정하고, r large의 Spot 가격은 m large(8Gi)와 비슷합니다.
          requirements = concat(local.graviton_spot_requirements, [
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["r"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["2"] },
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

          # m·r large. r은 같은 vCPU에 메모리가 두 배라 m 기준 배치가 그대로 맞고, 후보 Spot pool을 늘려
          # 회수와 용량 부족을 줄입니다.
          requirements = concat(local.graviton_spot_requirements, [
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["m", "r"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["2"] },
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
        memory = "${var.general_max_cpu * 8}Gi"
      }
    }
  }
}

# Agent Runway에서 architecture amd64를 고른 앱 Pod를 받습니다(agent-platform docs/DELIVERY_V5.md).
# app-deploy가 nodeSelector kubernetes.io/arch=amd64와 이 taint의 toleration을 씁니다. 다른 Pod는 들어오지 않으므로
# 그런 앱이 없으면 노드도 없습니다.
resource "kubernetes_manifest" "general_amd64" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      name = "general-amd64"
    }

    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }

          taints = [{ key = "opspresso.com/arch", value = "amd64", effect = "NoSchedule" }]

          # general과 같은 large(2 vCPU) Spot 노드입니다. c(4Gi)를 더해 후보 Spot pool을 늘립니다.
          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["c", "m", "r"] },
            { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = ["2"] },
          ]
        }
      }

      # 마지막 앱 Pod가 떠나면 노드를 회수합니다.
      disruption = {
        consolidationPolicy = "WhenEmpty"
        consolidateAfter    = "5m"
        budgets             = [{ nodes = "1" }]
      }

      limits = {
        cpu    = tostring(var.general_amd64_max_cpu)
        memory = "${var.general_amd64_max_cpu * 8}Gi"
      }
    }
  }
}
