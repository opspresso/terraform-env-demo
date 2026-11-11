variable "name" {
  description = "EKS 클러스터 이름을 입력합니다."
  type        = string
  default     = "eks-demo"
}

variable "kubernetes_version" {
  description = "쿠버네티스 버전을 입력합니다."
  type        = string
  default     = "1.37"
}

variable "endpoint_public_access_cidrs" {
  description = "EKS 퍼블릭 API 엔드포인트에 접근 가능한 CIDR 을 입력합니다. 운영 환경에서는 사무실/VPN 대역으로 좁힙니다."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ip_family" {
  description = "IP 주소 체계를 입력합니다. ipv4, ipv6"
  type        = string
  default     = "ipv4" # ipv4, ipv6
}

variable "sso_admin_permission_sets" {
  description = "클러스터 관리자 권한을 줄 IAM Identity Center permission set 이름입니다. 이 계정에 역할이 없는 이름은 건너뜁니다."
  type        = list(string)
  default     = ["sso-opspresso"]
}
