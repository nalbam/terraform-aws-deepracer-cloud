# backend

terraform {
  required_version = "1.1.7"

  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "terraform-workshop-082867736673"
    key            = "deepracer-local.tfstate"
    dynamodb_table = "terraform-resource-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}
