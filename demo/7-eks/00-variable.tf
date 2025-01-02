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
      group = "workers"
    }
  }
}

variable "node_security_group_additional_rules" {
  description = "node security group additional rules"
  type        = any
  default = {
    ingress_all_self_cluster = {
      description                   = "Cluster API to node all"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_all_self_node = {
      description = "Node to node all"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }
}
