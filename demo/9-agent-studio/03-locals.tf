# locals

locals {
  account_id = data.aws_caller_identity.current.account_id

  # 이름이 곧 환경입니다. 현재는 alpha 하나만 관리합니다.
  envs = {
    alpha = { base = "agent-studio" }
  }

  names = {
    for env, cfg in local.envs : env => {
      static = "${cfg.base}-static"
    }
  }

  tags = {
    Environment = "demo"
    ManagedBy   = "CloudManager"
    Project     = "terraform-env-demo/demo/9-agent-studio"
  }
}
