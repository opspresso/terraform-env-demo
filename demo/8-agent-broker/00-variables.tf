variable "region" {
  description = "Agent Broker를 실행하는 리전입니다."
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "Agent Broker가 테넌트 Pod Identity를 만드는 EKS 클러스터 이름입니다."
  type        = string
  default     = "eks-demo"
}
