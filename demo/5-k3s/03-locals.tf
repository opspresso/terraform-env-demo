# locals

locals {
  account_id = data.aws_caller_identity.current.account_id

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/5-k3s"
  }
}
