# backend

terraform {
  # required_version = "1.3.5"

  # backend "s3" {
  #   region         = "ap-northeast-2"
  #   bucket         = "terraform-workshop-968005369378"
  #   key            = "deepracer-local.tfstate"
  #   dynamodb_table = "terraform-resource-lock"
  #   encrypt        = true
  # }
  cloud {
    organization = "vscode-projects"

    workspaces {
      name = "drfc-baadal"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 3.74.2"
    }
  }
}


