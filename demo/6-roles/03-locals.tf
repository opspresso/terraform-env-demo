# locals

locals {
  policies = [for file in fileset(path.module, "policies/*.json") : replace(basename(file), ".json", "")]

  additional_policies = {
    "aws-ebs-csi-driver" = {
      policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    }
  }

  tags = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-env-demo/demo/6-role"
  }
}
