# backend

terraform {
  required_version = "1.2.9"

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
      version = "4.38.0"
    }
  }
}
