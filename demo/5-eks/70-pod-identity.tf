# Pod Identity Association

# 역할은 4-role 이 만들고, 그것을 이 클러스터의 서비스 계정에 묶는 것은 여기서 합니다.
# 묶으려면 클러스터가 있어야 하므로 클러스터를 만드는 쪽의 일이고, 그래서 4-role 은
# 이 모듈을 전혀 알지 못합니다 — 번호 순서가 곧 의존 순서입니다.
#
# 예전에는 role 쪽이 이것을 들고 있었고, 클러스터 이름을 문자열 `"eks-demo"` 로 적어
# 두는 것으로 그 의존을 숨겼습니다. 옮기면서 실제 참조로 바꿨습니다.
#
# 클러스터를 새로 세우면 여기서 association 도 새로 만들어집니다 — association 은
# 클러스터와 수명이 같아서, 옮겨 심을 것이 아니라 다시 만들어지는 것이 맞습니다.

locals {
  # 모든 클러스터가 갖는 애드온.
  common_targets = {
    "external-dns" = {
      namespace       = "addon-external-dns"
      service_account = "external-dns"
    }
    "external-secrets" = {
      namespace       = "addon-external-secrets"
      service_account = "external-secrets"
    }
  }

  # 이 클러스터에만 있는 것.
  demo_targets = {
    "atlantis" = {
      namespace       = "addon-atlantis"
      service_account = "atlantis"
    }
    "agent-studio" = {
      namespace       = "agent-studio"
      service_account = "agent-studio"
    }
    "mcp-cloudwatch" = {
      namespace       = "agent-mcps"
      service_account = "mcp-cloudwatch"
    }
    "mcp-memory" = {
      namespace       = "agent-mcps"
      service_account = "mcp-memory"
    }
  }

  # ARN 을 문자열로 조립하지 않고 4-role 이 내보낸 것을 씁니다. 키가 없으면 여기서
  # 실패하는 편이 낫습니다 — 조립한 ARN 은 존재하지 않는 역할을 가리켜도 apply 가
  # 통과하고, 파드가 자격증명을 못 받는 것으로 나타납니다.
  role_arns = data.terraform_remote_state.role.outputs.role_arns
}

resource "aws_eks_pod_identity_association" "common" {
  for_each = local.common_targets

  # 하드코딩된 이름이 아니라 이 모듈이 만든 클러스터입니다.
  cluster_name = module.eks.cluster_name

  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = local.role_arns[each.key]
}

resource "aws_eks_pod_identity_association" "demo" {
  for_each = local.demo_targets

  cluster_name = module.eks.cluster_name

  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = local.role_arns[each.key]
}
