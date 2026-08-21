# data

data "aws_caller_identity" "current" {
}

data "aws_sqs_queue" "render_dead_letter" {
  name = "comfy-render-dev-render-dlq"
}
