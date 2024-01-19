# variable

variable "region" {
  description = "리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름을 입력합니다."
  default     = "eks-demo-b" # cluster_name for eks-demo-b
}

variable "kubernetes_version" {
  description = "쿠버네티스 버전을 입력합니다."
  default     = "1.28" # kubernetes_version for eks-demo-b
}

variable "addons_version" {
  description = "EKS Addons 버전을 입력 합니다."
  default = {
    "coredns" : "v1.10.1-eksbuild.7"
    "kube-proxy" : "v1.28.4-eksbuild.4"
    "vpc-cni" : "v1.16.0-eksbuild.1"
  }
}

variable "ip_family" {
  default = "ipv4" # ipv4, ipv6
}

variable "key_name" {
  default = "bruce-seoul"
}
