# variable

variable "region" {
  description = "리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름을 입력합니다."
  default     = "eks-demo"
}

variable "cluster_version" {
  description = "쿠버네티스 버전을 입력합니다."
  default     = "1.31"
}

variable "ip_family" {
  description = "IP 주소 체계를 입력합니다. ipv4, ipv6"
  default     = "ipv4" # ipv4, ipv6
}

variable "key_name" {
  description = "키 이름을 입력합니다."
  default     = "bruce-seoul"
}

variable "self_managed_node_groups" {
  description = "self managed node groups"
  type        = any
  default = {
    workers = {
      group         = "workers"
      instance_type = "c6i.xlarge"
    }
  }
}
