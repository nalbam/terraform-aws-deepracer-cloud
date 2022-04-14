# aws_launch_template

resource "aws_launch_template" "worker" {
  name_prefix = format("%s-", var.name)

  image_id = local.ami_id

  user_data = base64encode(templatefile("bin/setup.sh", { region = var.region }))

  instance_type = var.instance_type
  key_name      = var.key_name
  ebs_optimized = var.ebs_optimized

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = var.delete_on_termination
      volume_size           = var.volume_size
      volume_type           = var.volume_type
      iops                  = var.iops
      throughput            = var.throughput
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.worker.name
  }

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    delete_on_termination       = var.delete_on_termination
    security_groups             = [aws_security_group.worker.id]
  }

  instance_market_options {
    market_type = "spot"
  }

  tag_specifications {
    resource_type = "instance"

    tags = local.tags
  }

  tag_specifications {
    resource_type = "volume"

    tags = local.tags
  }

  tags = local.tags
}
