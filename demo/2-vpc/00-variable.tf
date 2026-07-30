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

variable "azs" {
  description = "활성화할 가용영역을 입력합니다. az_subnets 의 키를 사용합니다."
  type        = list(string)

  # AZ 추가는 반드시 리스트 "끝"에 append 합니다. 제거도 "끝"에서만 합니다.
  # vpc 모듈이 count 기반이라 리스트 인덱스가 곧 리소스 주소이며,
  # 중간에 삽입/삭제하면 뒤쪽 AZ 의 subnet 이 전부 재생성됩니다.
  default = [
    "a",
    "c",
  ]

  validation {
    condition     = alltrue([for az in var.azs : contains(keys(var.az_subnets), az)])
    error_message = "azs 의 모든 항목은 az_subnets 에 정의되어 있어야 합니다."
  }
}

variable "az_subnets" {
  description = "AZ 별 서브넷 CIDR 을 입력합니다. 리스트 순서와 무관하게 AZ 문자에 CIDR 이 고정됩니다."
  type = map(object({
    public  = string
    private = string
    intra   = optional(string)
  }))
  default = {
    a = { public = "10.10.16.0/20", private = "10.10.112.0/20" } # intra = "10.10.208.0/20"
    b = { public = "10.10.32.0/20", private = "10.10.128.0/20" } # intra = "10.10.224.0/20"
    c = { public = "10.10.48.0/20", private = "10.10.144.0/20" } # intra = "10.10.240.0/20"
  }
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
