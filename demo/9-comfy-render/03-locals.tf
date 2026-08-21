# locals

locals {
  table_name  = "comfy-render-dev"
  bucket_name = "comfy-render-static"

  tags = {
    Environment = "demo"
    ManagedBy   = "CloudManager"
    Project     = "terraform-env-demo/demo/9-comfy-render"
  }
}
