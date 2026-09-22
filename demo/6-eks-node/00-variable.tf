# variable

variable "auto_mode_baseline_replicas" {
  description = "EKS Auto Mode가 유지할 기준 노드 수를 입력합니다."
  type        = number
  default     = 2

  validation {
    condition     = var.auto_mode_baseline_replicas >= 1
    error_message = "auto_mode_baseline_replicas는 1 이상이어야 합니다."
  }
}
