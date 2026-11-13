variable "baseline_zones" {
  description = "기준 노드를 둘 AZ 목록입니다. default NodeClass의 private subnet AZ와 일치해야 합니다."
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]

  validation {
    condition     = length(var.baseline_zones) >= 2 && length(distinct(var.baseline_zones)) == length(var.baseline_zones)
    error_message = "baseline_zones는 서로 다른 AZ 2개 이상이어야 합니다."
  }
}

variable "auto_mode_baseline_replicas_per_zone" {
  description = "EKS Auto Mode가 AZ마다 유지할 기준 노드 수를 입력합니다."
  type        = number
  # One 2-vCPU r Spot node (16Gi) per AZ holds the restartable workloads; the critical services run on the core
  # NodePools. One Spot reclaim takes half of this capacity, and general adds nodes until Spot returns.
  default = 1

  validation {
    condition     = var.auto_mode_baseline_replicas_per_zone >= 1 && floor(var.auto_mode_baseline_replicas_per_zone) == var.auto_mode_baseline_replicas_per_zone
    error_message = "auto_mode_baseline_replicas_per_zone은 1 이상의 정수여야 합니다."
  }
}

variable "general_max_cpu" {
  description = "dynamic general NodePool이 baseline 밖에서 추가할 수 있는 최대 vCPU 수입니다."
  type        = number
  default     = 16

  validation {
    condition     = var.general_max_cpu >= 4 && floor(var.general_max_cpu) == var.general_max_cpu
    error_message = "general_max_cpu는 4 이상의 정수여야 합니다."
  }
}

variable "general_amd64_max_cpu" {
  description = "dynamic general-amd64 NodePool이 amd64 앱 Pod를 위해 추가할 수 있는 최대 vCPU 수입니다."
  type        = number
  default     = 16

  validation {
    condition     = var.general_amd64_max_cpu >= 2 && floor(var.general_amd64_max_cpu) == var.general_amd64_max_cpu
    error_message = "general_amd64_max_cpu는 2 이상의 정수여야 합니다."
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
