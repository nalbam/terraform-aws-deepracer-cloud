# backend

terraform {
  required_version = "1.1.7"

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-968005369378"
    key            = "deepracer-local.tfstate"
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.75.1"
    }
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    region = "ap-northeast-2"
    bucket = "terraform-workshop-968005369378"
    key    = "vpc-demo.tfstate"
  }
}
