# locals

locals {
  account_id = data.aws_caller_identity.current.account_id
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.default.id

  tags = {
    "Name" = var.name
  }

  asg_tags = [
    for item in keys(local.tags) :
    tomap({
      "key"                 = item
      "value"               = element(values(local.tags), index(keys(local.tags), item))
      "propagate_at_launch" = true
    })
  ]
}
