variable "region" {
  description = "Agent Broker를 실행하는 리전입니다."
  type        = string
  default     = "ap-northeast-2"
}

locals {
  # Session tags that EKS Pod Identity adds to every credential; they are transitive.
  pod_identity_tag_keys = ["eks-cluster-arn", "eks-cluster-name", "kubernetes-namespace", "kubernetes-service-account", "kubernetes-pod-name", "kubernetes-pod-uid"]
}

variable "cluster_name" {
  description = "Agent Broker가 테넌트 Pod Identity를 만드는 EKS 클러스터 이름입니다."
  type        = string
  default     = "eks-demo"
}
