locals {
  # The backend and remote state blocks cannot read locals and repeat this region.
  region = "ap-northeast-2"

  account_id = data.aws_caller_identity.current.account_id

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/5-k3s"
  }
}
