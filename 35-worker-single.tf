# aws_autoscaling_group

resource "aws_autoscaling_group" "worker" {
  name_prefix = format("%s-", var.name)

  min_size = var.min
  max_size = var.max

  desired_capacity = var.desired

  vpc_zone_identifier = local.subnet_ids

  suspended_processes = var.suspended_processes

  target_group_arns = aws_lb_target_group.http.*.arn

  launch_template {
    id      = aws_launch_template.worker.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.asg_tags
}
