# eip

data "aws_instances" "worker" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.worker.name
  }

  depends_on = [aws_autoscaling_group.worker]
}

resource "aws_eip" "worker" {
  instance = data.aws_instances.worker.ids.0

  vpc = true

  tags = local.tags
}
