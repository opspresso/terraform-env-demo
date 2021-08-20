# variable

variable "region" {
  description = "생성될 리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "name" {
  description = "생성될 VPC 이름을 입력합니다."
  default     = "vpc-demo"
}

variable "cidr" {
  description = "생성될 cidr 를 입력합니다."
  default     = "10.10.0.0/16"
}
