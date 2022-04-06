# data

data "aws_caller_identity" "current" {
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "default" {
  # Deep Learning Base AMI (Ubuntu 18.04) Version 52.0
  # ami-098c6f323d2242d15

  owners = ["898082745236"]

  most_recent = true

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["Deep Learning Base AMI (Ubuntu 18.04) *"]
  }
}

data "template_file" "setup" {
  template = file("template/setup.sh")
}
