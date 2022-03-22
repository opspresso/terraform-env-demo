# variable

variable "region" {
  description = "생성될 리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "name" {
  description = "생성될 VPN 이름을 입력합니다."
  default     = "vpn-demo"
}

variable "customer_gateways" {
  description = "Maps of Customer Gateway's attributes (BGP ASN and Gateway's Internet-routable external IP address)"
  type        = map(map(any))
  default = {
    IP1 = {
      bgp_asn    = 65220
      ip_address = "39.117.14.79"
    },
  }
}
