variable "create_github_oidc_provider" {
  description = "GitHub Actions OIDC provider를 이 root에서 만들지 정합니다. false이면 계정에 이미 있는 provider를 사용합니다."
  type        = bool
  default     = false
}
