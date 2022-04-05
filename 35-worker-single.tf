# worker

resource "aws_autoscaling_group" "worker" {
  name_prefix = format("%s-", var.name)

  min_size = var.min
  max_size = var.max

  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  tags = local.asg_tags
}
