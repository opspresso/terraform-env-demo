# variable

variable "region" {
  description = "리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름을 입력합니다."
  default     = "eks-demo-a" # for eks-demo-a
}

variable "kubernetes_version" {
  description = "쿠버네티스 버전을 입력합니다."
  default     = "1.24"
}

variable "addons_version" {
  description = "EKS Addons 버전을 입력 합니다."
  default = {
    # "coredns" : "v1.8.4-eksbuild.1"
    # "kube-proxy" : "v1.21.14-eksbuild.2"
    # "vpc-cni" : "v1.11.2-eksbuild.1"
  }
}

variable "ip_family" {
  default = "ipv4" # ipv4, ipv6
}

variable "key_name" {
  default = "bruce-seoul"
}
