# variable

variable "region" {
  description = "리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "name" {
  description = "EKS 클러스터 이름을 입력합니다."
  default     = "eks-demo"
}

variable "kubernetes_version" {
  description = "쿠버네티스 버전을 입력합니다."
  default     = "1.36"
}

variable "endpoint_public_access_cidrs" {
  description = "EKS 퍼블릭 API 엔드포인트에 접근 가능한 CIDR 을 입력합니다. 운영 환경에서는 사무실/VPN 대역으로 좁힙니다."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ip_family" {
  description = "IP 주소 체계를 입력합니다. ipv4, ipv6"
  default     = "ipv4" # ipv4, ipv6
}
