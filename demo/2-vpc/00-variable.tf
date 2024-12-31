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

variable "public_subnets" {
  description = "public subnet 을 입력합니다."
  default = [
    "10.10.16.0/20",
    "10.10.32.0/20",
    "10.10.48.0/20",
  ]
}

variable "private_subnets" {
  description = "private subnet 을 입력합니다."
  default = [
    "10.10.112.0/20",
    "10.10.128.0/20",
    "10.10.144.0/20",
  ]
}

variable "intra_subnets" {
  description = "intra subnet 을 입력합니다."
  default = [
    # "10.10.208.0/20",
    # "10.10.224.0/20",
    # "10.10.240.0/20",
  ]
}

variable "enable_nat_gateway" {
  description = "nat gateway 를 사용할지 여부를 입력합니다."
  default     = true
}

variable "single_nat_gateway" {
  description = "single nat gateway 를 사용할지 여부를 입력합니다."
  default     = true
}

variable "enable_ipv6" {
  description = "ipv6 를 사용할지 여부를 입력합니다."
  default     = false
}

variable "enable_dns_hostnames" {
  description = "dns 호스트 이름을 사용할지 여부를 입력합니다."
  default     = true
}
