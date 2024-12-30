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

data "terraform_remote_state" "role" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-396608815058"
    key    = "backend/demo/role-demo/terraform.tfstate"
  }
}
