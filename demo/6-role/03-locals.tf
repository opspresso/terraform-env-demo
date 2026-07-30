# locals

locals {
  # policies/*.json 파일 하나당 인라인 정책 1개를 만듭니다.
  policies = [for file in fileset(path.module, "policies/*.json") : replace(basename(file), ".json", "")]

  # AWS 관리형 정책만 붙이는 역할. 여기 키는 policies/ 에 파일이 없어도 됩니다.
  additional_policies = {
    "atlantis" = {
      # Atlantis 는 임의의 Terraform 을 실행하므로 계정 전체 권한이 필요합니다.
      # 인라인 "*" 정책 대신 의도가 드러나는 AWS 관리형 정책을 사용합니다.
      policy = "arn:aws:iam::aws:policy/AdministratorAccess"
    }
    # "cloudwatch-agent" = {
    #   policy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    # }
  }

  # 역할은 인라인 정책과 관리형 정책 양쪽의 합집합으로 만듭니다.
  roles = toset(concat(local.policies, keys(local.additional_policies)))

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/6-role"
  }
}
