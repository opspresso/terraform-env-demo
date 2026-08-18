# Bedrock Knowledge Base

resource "aws_bedrockagent_knowledge_base" "this" {
  for_each = local.names

  name     = each.value.knowledge
  role_arn = aws_iam_role.knowledge_base[each.key].arn

  knowledge_base_configuration {
    type = "VECTOR"

    vector_knowledge_base_configuration {
      embedding_model_arn = format("arn:aws:bedrock:%s::foundation-model/%s", var.region, var.embedding_model)
    }
  }

  storage_configuration {
    type = "S3_VECTORS"

    # 인덱스를 여기서 만들었으므로 그 ARN 하나만 넘깁니다. `vector_bucket_arn` 은
    # Bedrock 이 인덱스를 직접 만들 때 쓰는 짝(+`index_name`)이고, 둘을 같이 줄 수는
    # 없습니다.
    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.knowledge[each.key].index_arn
    }
  }

  tags = {
    Name = each.value.knowledge
  }

  # 롤이 인덱스와 버킷에 닿을 수 있게 된 뒤에 만들어져야 합니다. Bedrock 은 생성 시점에
  # 벡터 스토어를 확인합니다.
  depends_on = [aws_iam_role_policy.knowledge_base]
}

resource "aws_bedrockagent_data_source" "documents" {
  for_each = local.names

  knowledge_base_id = aws_bedrockagent_knowledge_base.this[each.key].id
  name              = each.value.documents

  # 데이터 소스를 지워도 벡터는 남깁니다. 되돌릴 수 없는 삭제를 계획 한 줄이 일으키지
  # 않게 하는 쪽을 고릅니다 — 필요하면 사람이 지웁니다.
  data_deletion_policy = "RETAIN"

  data_source_configuration {
    type = "S3"

    s3_configuration {
      bucket_arn = aws_s3_bucket.documents[each.key].arn
    }
  }

  # 청킹은 기본값(FIXED_SIZE)입니다. S3 Vectors 에서 hierarchical 청킹은 부모-자식 관계를
  # non-filterable 메타데이터로 넣어 벡터당 1KB 한도를 넘길 수 있습니다.
}
