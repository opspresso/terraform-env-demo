# remote

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-396608815058"
    key    = "backend/demo/vpc-demo/terraform.tfstate"
  }
}

data "terraform_remote_state" "alb" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-396608815058"
    key    = "backend/demo/alb-demo/terraform.tfstate"
  }
}

# 4-role 이 만든 역할들. Pod Identity association 이 그 ARN 을 필요로 합니다.
data "terraform_remote_state" "role" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-396608815058"
    key    = "backend/demo/role-demo/terraform.tfstate"
  }
}
