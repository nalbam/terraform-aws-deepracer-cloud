# aws_autoscaling_group

resource "aws_autoscaling_group" "worker" {
  name_prefix = format("%s-", var.name)

  min_size = var.min
  max_size = var.max

  desired_capacity = var.desired

  vpc_zone_identifier = local.subnet_ids

  # suspended_processes = var.suspended_processes

  # target_group_arns = aws_lb_target_group.http.*.arn

  # launch_template {
  #   id      = aws_launch_template.worker.id
  #   version = "$Latest"
  # }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.on_demand_base
      on_demand_percentage_above_base_capacity = var.on_demand_rate
      spot_allocation_strategy                 = var.spot_strategy
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.worker.id
        version            = "$Latest"
      }

      override {
        instance_type = var.instance_type
        # weighted_capacity = 10
      }
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
