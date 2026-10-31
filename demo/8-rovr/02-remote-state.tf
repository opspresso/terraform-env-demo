data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-396608815058"
    key    = "backend/demo/vpc-demo/terraform.tfstate"
  }
}

# Auto Mode 노드가 쓰는 EKS 관리 primary security group을 NFS 허용 대상으로 씁니다.
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-396608815058"
    key    = "backend/demo/eks-demo/terraform.tfstate"
  }
}
