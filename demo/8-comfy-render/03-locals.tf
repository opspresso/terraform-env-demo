# locals

locals {
  account_id        = data.aws_caller_identity.current.account_id
  table_name        = "comfy-render-dev"
  bucket_name       = "comfy-render-static"
  render_queue_name = "comfy-render-dev-render-queue"
  render_dlq_name   = "comfy-render-dev-render-dlq"
  amplify_app_id    = "d136e8x9dkhdxg"

  tags = {
    Environment = "demo"
    ManagedBy   = "CloudManager"
    Project     = "terraform-env-demo/demo/9-comfy-render"
  }
}
