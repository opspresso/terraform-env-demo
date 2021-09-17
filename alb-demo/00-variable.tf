# variable

variable "region" {
  description = "리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "name" {
  description = "생성될 ALB 이름을 입력합니다."
  default     = "demo"
}

variable "domain" {
  description = "생성될 ALB 도메인을 입력합니다."
  default     = "bruce.opspresso.com"
}
