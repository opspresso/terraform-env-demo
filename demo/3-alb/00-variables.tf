variable "name" {
  description = "생성될 ALB 이름을 입력합니다."
  type        = string
  default     = "demo"
}

variable "root_domain" {
  description = "listener rule 의 host_header 가 사용하는 ROOT 도메인을 입력합니다. (argocd, grafana, *.demo-a 등)"
  type        = string
  default     = "opsp.dev"
}

variable "domains" {
  description = <<-EOT
    ALB 가 서비스할 도메인을 입력합니다. 키는 Route53 hosted zone(ROOT 도메인) 이름입니다.
      certificates - HTTPS 리스너에 붙일 ACM 인증서의 도메인. var.issued_certificates 에 있으면 이 디렉터리가 발급합니다
                     (도메인과 *.도메인, Route53 DNS 검증). 나머지는 사전 발급된 인증서를 조회합니다.
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
    # Management cluster addons (Argo CD, Grafana, Keep, Loki, Prometheus) on demo, and the future
    # service clusters eks-demo-a/b on demo-a/demo-b.
    "opsp.dev" = {
      certificates = ["demo.opsp.dev", "demo-a.opsp.dev", "demo-b.opsp.dev"]
      public       = ["*.demo.opsp.dev", "*.demo-a.opsp.dev", "*.demo-b.opsp.dev"]
      internal     = ["*.demo-in.opsp.dev", "*.demo-in-a.opsp.dev", "*.demo-in-b.opsp.dev"]
    }
    # The rovr SaaS on the apex rovr.dev (argocd-env-apps docs/rovr.md) and the apps that Agent Runway
    # deploys on apps (agent-platform docs/APP_DELIVERY.md).
    "rovr.dev" = {
      certificates = ["rovr.dev", "apps.rovr.dev"]
      public       = ["rovr.dev", "*.apps.rovr.dev"]
      internal     = []
    }
    "agrt.dev" = {
      certificates = ["agrt.dev"]
      # Agent service hosts (studio, memory, knowledge, forge, models, delivery) resolve to the EKS ALB.
      public   = ["*.agrt.dev"]
      internal = []
    }
  }
}

variable "primary_domain" {
  description = "HTTPS 리스너의 기본(default) 인증서로 쓸 도메인을 입력합니다. 나머지는 SNI 로 추가됩니다."
  type        = string
  default     = "demo.opsp.dev"

  validation {
    condition     = contains(flatten([for domain in var.domains : domain.certificates]), var.primary_domain)
    error_message = "primary_domain 은 domains 의 certificates 에 포함된 도메인이어야 합니다."
  }
}

variable "issued_certificates" {
  description = "이 디렉터리가 ACM으로 발급·검증하는 인증서 도메인입니다. 각 도메인과 와일드카드(*.도메인)를 포함합니다."
  type        = list(string)
  default     = ["rovr.dev", "apps.rovr.dev", "demo.opsp.dev", "demo-a.opsp.dev", "demo-b.opsp.dev"]
}
