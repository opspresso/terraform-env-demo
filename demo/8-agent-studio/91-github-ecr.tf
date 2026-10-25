# Release identities are separate from runtime Pod Identity and node pull access.
locals {
  github_ecr_publishers = {
    agent-studio = {
      repository_id = "1307383317"
      description   = "github--agent-studio-ecr role"
      legacy_trust  = true
    }
    agent-memory = {
      repository_id = "1345706960"
      description   = "agent-memory ECR push from GitHub Actions OIDC"
      legacy_trust  = true
    }
    agent-librio = {
      repository_id = "1363501685"
      description   = "agent-librio release ECR push from GitHub Actions OIDC"
      legacy_trust  = false
    }
    agent-forge = {
      repository_id = "1379377605"
      description   = "agent-forge release ECR push from GitHub Actions OIDC"
      legacy_trust  = false
    }
    agent-models = {
      repository_id = "1339315923"
      description   = "agent-models release ECR push from GitHub Actions OIDC"
      legacy_trust  = false
    }
  }
  github_ecr_subject_prefixes = {
    for repository, publisher in local.github_ecr_publishers : repository =>
    "repo:opspresso@38965494/${repository}@${publisher.repository_id}"
  }
  github_ecr_push_actions = [
    "ecr:BatchCheckLayerAvailability",
    "ecr:BatchGetImage",
    "ecr:CompleteLayerUpload",
    "ecr:InitiateLayerUpload",
    "ecr:PutImage",
    "ecr:UploadLayerPart",
  ]
}

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_ecr" {
  for_each = local.github_ecr_publishers

  name                 = "github--${each.key}-ecr"
  description          = each.value.description
  max_session_duration = 3600
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike = {
          # Preserve the two imported roles' existing trust. New publishers only
          # accept immutable repository subjects and v* release tags.
          "token.actions.githubusercontent.com:sub" = each.value.legacy_trust ? [
            "${local.github_ecr_subject_prefixes[each.key]}:ref:refs/tags/v*",
            "${local.github_ecr_subject_prefixes[each.key]}:ref:refs/heads/main",
            "repo:opspresso/${each.key}:ref:refs/tags/v*",
            "repo:opspresso/${each.key}:ref:refs/heads/main",
          ] : ["${local.github_ecr_subject_prefixes[each.key]}:ref:refs/tags/v*"]
        }
      }
    }]
  })

  tags = {
    Name      = "github--${each.key}-ecr"
    ManagedBy = "Terraform"
    Project   = each.key
  }
}

resource "aws_iam_policy" "github_ecr" {
  for_each = { for repository, publisher in local.github_ecr_publishers : repository => publisher if repository != "agent-memory" }

  name = "github--${each.key}-ecr"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      {
        Effect = "Allow"
        # Forge verifies its published Sandbox by pulling and running that image.
        Action   = each.key == "agent-forge" ? concat(local.github_ecr_push_actions, ["ecr:GetDownloadUrlForLayer"]) : local.github_ecr_push_actions
        Resource = aws_ecr_repository.this[each.key].arn
      },
    ]
  })

  tags = {
    Name      = "github--${each.key}-ecr"
    ManagedBy = "Terraform"
    Project   = each.key
  }
}

resource "aws_iam_role_policy_attachment" "github_ecr" {
  for_each = aws_iam_policy.github_ecr

  role       = aws_iam_role.github_ecr[each.key].name
  policy_arn = each.value.arn
}

# Memory already has an inline policy. Import it without a detach/reattach or
# changing its existing image-layer read permission during adoption.
resource "aws_iam_role_policy" "github_ecr_memory" {
  name = "ecr-push-agent-memory"
  role = aws_iam_role.github_ecr["agent-memory"].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = "ecr:GetAuthorizationToken", Resource = "*" },
      {
        Effect   = "Allow"
        Action   = concat(local.github_ecr_push_actions, ["ecr:GetDownloadUrlForLayer"])
        Resource = aws_ecr_repository.this["agent-memory"].arn
      },
    ]
  })
}

import {
  for_each = toset(["agent-studio", "agent-memory"])
  to       = aws_iam_role.github_ecr[each.key]
  id       = "github--${each.key}-ecr"
}

import {
  to = aws_iam_policy.github_ecr["agent-studio"]
  id = "arn:aws:iam::396608815058:policy/github--agent-studio-ecr"
}

import {
  to = aws_iam_role_policy_attachment.github_ecr["agent-studio"]
  id = "github--agent-studio-ecr/arn:aws:iam::396608815058:policy/github--agent-studio-ecr"
}

import {
  to = aws_iam_role_policy.github_ecr_memory
  id = "github--agent-memory-ecr:ecr-push-agent-memory"
}
