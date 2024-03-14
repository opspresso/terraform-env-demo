# variable

variable "region" {
  description = "리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름을 입력합니다."
  default     = "eks-demo" # cluster_name for eks-demo
}

variable "kubernetes_version" {
  description = "쿠버네티스 버전을 입력합니다."
  default     = "1.29" # kubernetes_version for eks-demo
}

variable "addons_version" {
  description = "EKS Addons 버전을 입력 합니다."
  default = {
    "coredns" : "v1.11.1-eksbuild.6"
    "kube-proxy" : "v1.29.1-eksbuild.2"
    "vpc-cni" : "v1.16.4-eksbuild.2"
    # "aws-ebs-csi-driver": "v0.10.0"
  }
}

variable "ip_family" {
  default = "ipv6" # ipv4, ipv6
}

variable "key_name" {
  default = "bruce-seoul"
}
