# remote

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-396608815058"
    key    = "backend/demo/vpc-demo/terraform.tfstate"
  }
}

# The EKS-managed cluster primary security group that Auto Mode nodes and Pods use.
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-396608815058"
    key    = "backend/demo/eks-demo/terraform.tfstate"
  }
}
