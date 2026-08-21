# SQS — 렌더 작업 큐

resource "aws_sqs_queue" "render" {
  name                       = local.render_queue_name
  visibility_timeout_seconds = 3600
  message_retention_seconds  = 345600
  max_message_size           = 1048576
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = data.aws_sqs_queue.render_dead_letter.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name = local.render_queue_name
  }

  lifecycle {
    prevent_destroy = true
  }
}
