# variable

variable "region" {
  description = "생성될 리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "name" {
  description = "생성될 이름을 입력합니다."
  default     = "atlantis"
}

variable "domain" {
  description = "생성될 도메인 이름을 입력합니다. (without trailing dot)"
  default     = "demo.opspresso.com"
}

# Github
variable "atlantis_github_user" {
  description = "GitHub username that is running the Atlantis command"
  default     = "nalbam-bot"
}

variable "atlantis_repo_allowlist" {
  description = "List of allowed repositories Atlantis can be used with"
  default = [
    "github.com/opspresso/terraform-*"
  ]
}
