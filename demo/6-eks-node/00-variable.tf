# variable

variable "workspace_max_pods" {
  description = "Workspace Pod capacity; keep aligned with argocd-env-apps env/eks-demo.yaml. Each Pod reserves 1 CPU and 2Gi memory."
  type        = number
  default     = 32
  validation {
    condition     = var.workspace_max_pods >= 1 && var.workspace_max_pods <= 128 && floor(var.workspace_max_pods) == var.workspace_max_pods
    error_message = "workspace_max_pods must be an integer between 1 and 128."
  }
}

variable "workspace_ephemeral_storage_gib" {
  description = "Encrypted Auto Mode node disk for Sandbox emptyDirs and the kubelet-managed image cache."
  type        = number
  default     = 160
  validation {
    condition     = var.workspace_ephemeral_storage_gib >= 80 && var.workspace_ephemeral_storage_gib <= 1000 && floor(var.workspace_ephemeral_storage_gib) == var.workspace_ephemeral_storage_gib
    error_message = "workspace_ephemeral_storage_gib must be an integer between 80 and 1000."
  }
}

variable "auto_mode_baseline_replicas" {
  description = "EKS Auto Mode가 유지할 기준 노드 수를 입력합니다."
  type        = number
  default     = 2

  validation {
    condition     = var.auto_mode_baseline_replicas >= 1
    error_message = "auto_mode_baseline_replicas는 1 이상이어야 합니다."
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
