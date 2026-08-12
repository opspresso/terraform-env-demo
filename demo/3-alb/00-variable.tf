# variable

variable "region" {
  description = "리전을 입력 합니다. e.g: ap-northeast-2"
  default     = "ap-northeast-2"
}

variable "name" {
  description = "생성될 ALB 이름을 입력합니다."
  default     = "demo"
}

variable "root_domain" {
  description = "listener rule 의 host_header 가 사용하는 ROOT 도메인을 입력합니다. (argocd, grafana, *.demo-a 등)"
  default     = "opspresso.com"
}

variable "domains" {
  description = <<-EOT
    ALB 가 서비스할 도메인을 입력합니다. 키는 Route53 hosted zone(ROOT 도메인) 이름입니다.
      certificates - HTTPS 리스너에 붙일 ACM 인증서의 도메인 (사전 발급 필요)
      public       - public ALB 로 향하는 A(alias) 레코드 이름 (FQDN, 와일드카드 가능)
      internal     - internal ALB 로 향하는 A(alias) 레코드 이름 (FQDN, 와일드카드 가능)
    도메인 추가/삭제는 블록 하나를 추가/삭제하면 됩니다.
  EOT

  type = map(object({
    certificates = list(string)
    public       = list(string)
    internal     = list(string)
  }))

  default = {
    "opspresso.com" = {
      certificates = [
        "demo.opspresso.com",
        "demo-a.opspresso.com",
        "demo-b.opspresso.com",
      ]
      public = [
        "*.demo.opspresso.com",
        "*.demo-a.opspresso.com",
        "*.demo-b.opspresso.com",
      ]
      internal = [
        "*.demo-in.opspresso.com",
        "*.demo-in-a.opspresso.com",
        "*.demo-in-b.opspresso.com",
      ]
    }

    "agentdure.com" = {
      certificates = [
        "agentdure.com",
      ]
      public = [
        "agentdure.com",
        "www.agentdure.com",
      ]
      internal = []
    }
  }
}

variable "primary_domain" {
  description = "HTTPS 리스너의 기본(default) 인증서로 쓸 도메인을 입력합니다. 나머지는 SNI 로 추가됩니다."
  default     = "demo.opspresso.com"

  validation {
    condition     = contains(flatten([for domain in var.domains : domain.certificates]), var.primary_domain)
    error_message = "primary_domain 은 domains 의 certificates 에 포함된 도메인이어야 합니다."
  }
}
