# variable

variable "region" {
  description = "리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "cluster_name" {
  description = "EKS 클러스터 이름을 입력합니다."
  default     = "eks-demo" # for eks-demo
}

variable "kubernetes_version" {
  description = "쿠버네티스 버전을 입력합니다."
  default     = "1.23"
}

variable "addons_version" {
  default = {
    "aws-ebs-csi-driver" : "v1.10.0-eksbuild.1"
    "coredns" : "v1.8.7-eksbuild.2"
    "kube-proxy" : "v1.23.7-eksbuild.1"
    "vpc-cni" : "v1.11.3-eksbuild.1"
  }
}

variable "key_name" {
  default = "bruce-seoul"
}
