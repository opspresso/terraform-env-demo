variable "region" {
  description = "생성될 리전을 입력 합니다. e.g: ap-northeast-2"
  type        = string
  default     = "ap-northeast-2"
}

variable "prefix_name" {
  description = "Pod Identity 역할 이름의 접두어입니다. 역할 이름은 `<prefix_name>--<policy>`입니다."
  type        = string
  default     = "pod-role"
}
