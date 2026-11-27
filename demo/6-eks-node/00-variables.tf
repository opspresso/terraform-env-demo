variable "core_zones" {
  description = "core 노드를 AZ마다 1대씩 둘 AZ 목록입니다. eks-demo는 비용 우선이라 단일 복제본 서비스의 EBS volume이 있는 ap-northeast-2c 하나만 둡니다."
  type        = list(string)
  default     = ["ap-northeast-2c"]

  validation {
    condition     = length(var.core_zones) >= 1 && length(distinct(var.core_zones)) == length(var.core_zones)
    error_message = "core_zones는 서로 다른 AZ 1개 이상이어야 합니다."
  }
}

variable "general_max_cpu" {
  description = "architecture별 general NodePool이 만들 수 있는 최대 vCPU 수입니다. Agent Runway 8xlarge rollout은 32 vCPU 노드 두 대를 씁니다."
  type        = map(number)
  default     = { arm64 = 96, amd64 = 80 }

  validation {
    condition     = alltrue([for a in ["arm64", "amd64"] : contains(keys(var.general_max_cpu), a) && var.general_max_cpu[a] >= 64 && floor(var.general_max_cpu[a]) == var.general_max_cpu[a]])
    error_message = "general_max_cpu는 arm64와 amd64 key에 64 이상의 정수를 가져야 합니다."
  }
}

variable "gha_runner_max_runners" {
  description = "GitHub Actions runner Pod capacity; keep aligned with maxRunners in argocd-env-addons charts/arc-runners. Each Pod reserves 2.5 CPU and 9Gi memory."
  type        = number
  default     = 6
  validation {
    condition     = var.gha_runner_max_runners >= 1 && var.gha_runner_max_runners <= 20 && floor(var.gha_runner_max_runners) == var.gha_runner_max_runners
    error_message = "gha_runner_max_runners must be an integer between 1 and 20."
  }
}

variable "gha_runner_ephemeral_storage_gib" {
  description = "Auto Mode node disk for runner work directories and the dind image store."
  type        = number
  default     = 200
  validation {
    condition     = var.gha_runner_ephemeral_storage_gib >= 80 && var.gha_runner_ephemeral_storage_gib <= 1000 && floor(var.gha_runner_ephemeral_storage_gib) == var.gha_runner_ephemeral_storage_gib
    error_message = "gha_runner_ephemeral_storage_gib must be an integer between 80 and 1000."
  }
}
