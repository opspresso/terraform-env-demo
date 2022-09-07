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
  default     = "1.22"
}

variable "addons_version" {
  default = {
    # for 1.22
    "coredns" : "v1.8.7-eksbuild.1"
    "kube-proxy" : "v1.22.11-eksbuild.2"
    "vpc-cni" : "v1.11.3-eksbuild.1"
    # # for 1.23
    # "aws-ebs-csi-driver" : "v1.10.0-eksbuild.1"
    # "coredns" : "v1.8.7-eksbuild.2"
    # "kube-proxy" : "v1.23.7-eksbuild.1"
    # "vpc-cni" : "v1.11.3-eksbuild.1"
  }
}

variable "addons_irsa_name" {
  default = {
    "aws-ebs-csi-driver" : "aws-ebs-csi-driver-sa"
    # "vpc-cni" : "aws-node"
  }
}

variable "ip_family" {
  default = "ipv4" # ipv4, ipv6
}

variable "key_name" {
  default = "bruce-seoul"
}
