# Knowledge Base 서비스 롤

# Bedrock 이 이 롤을 빌려 문서를 읽고, 임베딩을 만들고, 인덱스에 씁니다. 파드 롤
# (demo/4-role) 과는 별개입니다 — 파드는 KB 를 *질의*할 뿐 수집하지 않습니다.
resource "aws_iam_role" "knowledge_base" {
  for_each = local.names

  name               = format("bedrock-kb--%s", each.value.knowledge)
  assume_role_policy = data.aws_iam_policy_document.knowledge_base_assume.json

  tags = {
    Name = format("bedrock-kb--%s", each.value.knowledge)
  }
}

data "aws_iam_policy_document" "knowledge_base" {
  for_each = local.names

  statement {
    sid    = "EmbeddingModel"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
    ]
    resources = [
      format("arn:aws:bedrock:%s::foundation-model/%s", var.region, var.embedding_model),
    ]
  }

  statement {
    sid    = "DocumentsList"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.documents[each.key].arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [local.account_id]
    }
  }

  statement {
    sid    = "DocumentsRead"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.documents[each.key].arn}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceAccount"
      values   = [local.account_id]
    }
  }

  # 이 KB 의 인덱스 하나로 좁힙니다. 같은 버킷 안의 카탈로그 인덱스와 mcp-memory 의
  # 인덱스는 Bedrock 이 손댈 것이 아닙니다.
  statement {
    sid    = "KnowledgeIndex"
    effect = "Allow"
    actions = [
      "s3vectors:GetIndex",
      "s3vectors:PutVectors",
      "s3vectors:GetVectors",
      "s3vectors:QueryVectors",
      "s3vectors:ListVectors",
      "s3vectors:DeleteVectors",
    ]
    resources = [
      aws_s3vectors_index.knowledge[each.key].index_arn,
    ]
  }

  statement {
    sid    = "KnowledgeVectorBucket"
    effect = "Allow"
    actions = [
      "s3vectors:GetVectorBucket",
    ]
    resources = [
      aws_s3vectors_vector_bucket.this[each.key].vector_bucket_arn,
    ]
  }
}

resource "aws_iam_role_policy" "knowledge_base" {
  for_each = local.names

  name   = format("bedrock-kb--%s", each.value.knowledge)
  role   = aws_iam_role.knowledge_base[each.key].id
  policy = data.aws_iam_policy_document.knowledge_base[each.key].json
}
