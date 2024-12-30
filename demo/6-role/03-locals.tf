# locals

locals {
  policies = [for file in fileset(path.module, "policies/*.json") : replace(basename(file), ".json", "")]

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/6-role"
  }
}
