# aws_eip

data "aws_instances" "worker" {
  count = var.desired > 0 ? 1 : 0

  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.worker.name
  }

  depends_on = [aws_autoscaling_group.worker]
}

# resource "aws_eip" "worker" {
#   instance = try(data.aws_instances.worker.0.ids.0, null)

#   vpc = true

#   tags = local.tags
# }

output "public_ip" {
  value = try(data.aws_instances.worker.0.public_ips.0, "")
  # value = aws_eip.worker.public_ip
}
