# remote

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-082867736673"
    key    = "backend/terraform-env-bruce/demo/vpc-demo/terraform.tfstate"
  }

  #   backend = "remote"
  #   config = {
  #     organization = "bruce"
  #     workspaces = {
  #       name = "vpc-demo"
  #     }
  #   }
}
