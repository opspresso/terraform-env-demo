# variable

variable "region" {
  description = "생성될 리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "k3s_go_memory_limit_mib" {
  description = "Soft Go runtime memory budget for the single-node alpha k3s server; not a process or Pod hard limit."
  type        = number
  default     = 1536

  validation {
    condition     = var.k3s_go_memory_limit_mib >= 1024 && var.k3s_go_memory_limit_mib <= 3072 && floor(var.k3s_go_memory_limit_mib) == var.k3s_go_memory_limit_mib
    error_message = "k3s_go_memory_limit_mib must be an integer from 1024 through 3072."
  }
}
