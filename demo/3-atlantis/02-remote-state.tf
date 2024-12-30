# remote

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-968005369378"
    key    = "backend/demo/vpc-demo/terraform.tfstate"
  }
}
