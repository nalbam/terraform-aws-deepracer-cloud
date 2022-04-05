# output

data "aws_instances" "worker" {
  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.worker.name
  }

  depends_on = [aws_autoscaling_group.worker]
}

output "worker_ips" {
  value = data.aws_instances.worker.public_ips
}
