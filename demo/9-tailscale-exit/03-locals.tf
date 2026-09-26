# locals

locals {
  name = "tailscale-exit"

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/9-tailscale-exit"
  }
}
