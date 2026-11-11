variable "k3s_go_memory_limit_mib" {
  description = "Soft Go runtime memory budget for the single-node k3s server; not a process or Pod hard limit."
  type        = number
  default     = 1536

  validation {
    condition     = var.k3s_go_memory_limit_mib >= 1024 && var.k3s_go_memory_limit_mib <= 3072 && floor(var.k3s_go_memory_limit_mib) == var.k3s_go_memory_limit_mib
    error_message = "k3s_go_memory_limit_mib must be an integer from 1024 through 3072."
  }
}

variable "ecr_repositories" {
  description = "Agent ECR repositories (owned by 8-agent-studio) the node may pull from."
  type        = list(string)
  default     = ["agent-runway", "agent-forge", "agent-knowledge", "agent-memory", "agent-models", "agent-studio"]
}

variable "ingress_zone" {
  description = "k3s ingress wildcard 레코드를 만들 Route53 public hosted zone입니다. 계정에 미리 있어야 합니다."
  type        = string
  default     = "agrt.dev"
}

variable "ingress_domain" {
  description = "k3s 노드의 public IP로 향하는 wildcard 레코드(*.<ingress_domain>)의 도메인입니다. ingress_zone 안에 있어야 합니다."
  type        = string
  default     = "demo.agrt.dev"

  validation {
    condition     = endswith(var.ingress_domain, ".${var.ingress_zone}")
    error_message = "ingress_domain은 ingress_zone의 하위 도메인이어야 합니다."
  }
}

variable "cert_manager_zones" {
  description = "k3s cert-manager가 DNS-01 검증 레코드를 쓸 Route53 public hosted zone입니다. 계정에 미리 있어야 합니다."
  type        = list(string)
  default     = ["rovr.dev", "agrt.dev"]
}

variable "key_name" {
  description = "k3s EC2에 연결할 기존 EC2 key pair 이름입니다. null이면 key pair 없이 SSM으로만 접속합니다."
  type        = string
  default     = "nalbam-bruce"
}
