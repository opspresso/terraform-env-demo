# EKS Auto Mode capacity on Graviton (arm64) Spot for workloads a restart does not harm
# Services a restart interrupts run on the on-demand core NodePools (51-core-node-pool.tf). A reclaimed node is replaced by Karpenter; a reclaimed
# baseline node leaves its AZ without a baseline node until Spot capacity returns.
# baseline은 AZ마다 기준 노드 수를 고정하고, 증가분은 같은 large 크기의 dynamic `general` NodePool이 처리합니다.
# 정적 NodePool은 노드를 AZ에 분산하지 않으므로 AZ별 NodePool을 둡니다. 한 AZ가 장애 나도 다른 AZ의 노드가 남습니다.
# 5-eks는 내장 general-purpose pool을 켜지 않으므로 앱 Pod는 이 arm64 노드에서 실행됩니다.
# amd64 이미지를 고른 Agent Runway 앱 Pod만 taint를 허용해 dynamic `general-amd64` NodePool에서 실행됩니다.
# large 노드에 들어가지 않는 큰 앱 Pod(Agent Runway 크기 xlarge 이상)는 `general-large`·`general-large-amd64`가 받습니다.
# 두 pool은 weight가 낮아 large에 들어가는 Pod를 위해 큰 노드를 만들지 않습니다. weight는 노드를 만들 때의 우선순위라서
# 이미 있는 큰 노드에 남는 자리에는 작은 Pod도 놓일 수 있습니다. 큰 pool의 통합이 그런 노드를 정리합니다.
# plan 시점에 EKS API가 필요하므로 5-eks를 먼저 적용합니다.

locals {
  # large(2 vCPU) pool이 큰 pool보다 먼저 선택됩니다. Karpenter는 weight가 높은 NodePool부터 고르고, 없으면 0입니다.
  large_pool_weight = 10
  # 큰 앱 Pod를 받는 노드 크기. Agent Runway 크기의 Pod는 같은 이름 instance의 vCPU 절반을 요청하므로
  # (4xlarge는 8 CPU·16Gi) 같은 이름의 노드에 DaemonSet과 함께 들어갑니다. 8xlarge rollout은 32 vCPU 노드 두 대를 씁니다.
  large_pod_instance_cpus = ["4", "8", "16", "32"]

  # 7세대 이상 Graviton Spot 인스턴스.
  graviton_spot_requirements = [
    { key = "kubernetes.io/arch", operator = "In", values = ["arm64"] },
    { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
    { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
    # 9세대 Graviton(Graviton5) 노드는 EKS Auto Mode 커널에서 network policy eBPF map 쓰기가 ENOMEM으로 실패해 Pod 통신이 막히므로 제외합니다.
    { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
    { key = "eks.amazonaws.com/instance-generation", operator = "NotIn", values = ["9"] },
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
      weight = local.large_pool_weight

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

# Agent Runway에서 architecture amd64를 고른 앱 Pod를 받습니다(agent-platform docs/APP_DELIVERY.md, Workflow).
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
      weight = local.large_pool_weight

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

# large(2 vCPU) 노드에 들어가지 않는 arm64 앱 Pod를 받습니다(Agent Runway 크기 xlarge 이상, agent-platform docs/APP_DELIVERY.md
# "크기"). weight가 `general`보다 낮아 large에 들어가는 Pod를 위해 이 노드를 만들지 않습니다.
resource "kubernetes_manifest" "general_large" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      name = "general-large"
    }

    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "eks.amazonaws.com"
            kind  = "NodeClass"
            name  = "default"
          }

          # c(2Gi/vCPU)를 더해 큰 크기의 후보 Spot pool을 늘립니다. 크기 Pod의 메모리는 vCPU당 2Gi입니다.
          requirements = concat(local.graviton_spot_requirements, [
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["c", "m", "r"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = local.large_pod_instance_cpus },
          ])
        }
      }

      # 큰 Pod가 떠난 뒤 남는 자리에 놓인 작은 Pod는 노드를 비우지 않으므로 활용도가 낮은 노드도 회수합니다. 큰 Pod는
      # 들어갈 다른 노드가 있을 때만 옮겨집니다.
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "5m"
        budgets             = [{ nodes = "1" }]
      }

      limits = {
        cpu    = tostring(var.general_large_max_cpu)
        memory = "${var.general_large_max_cpu * 8}Gi"
      }
    }
  }
}

# `general-large`의 amd64 짝입니다. `general-amd64`와 같은 taint를 달아 amd64를 고른 앱 Pod만 받습니다.
resource "kubernetes_manifest" "general_large_amd64" {
  manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"

    metadata = {
      name = "general-large-amd64"
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

          requirements = [
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64"] },
            { key = "kubernetes.io/os", operator = "In", values = ["linux"] },
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
            { key = "eks.amazonaws.com/instance-category", operator = "In", values = ["c", "m", "r"] },
            { key = "eks.amazonaws.com/instance-generation", operator = "Gt", values = ["6"] },
            { key = "eks.amazonaws.com/instance-cpu", operator = "In", values = local.large_pod_instance_cpus },
          ]
        }
      }

      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "5m"
        budgets             = [{ nodes = "1" }]
      }

      limits = {
        cpu    = tostring(var.general_large_amd64_max_cpu)
        memory = "${var.general_large_amd64_max_cpu * 8}Gi"
      }
    }
  }
}
