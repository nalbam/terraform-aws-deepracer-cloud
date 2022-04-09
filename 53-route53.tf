# aws_route53

data "aws_instances" "worker" {
  count = var.desired > 0 ? 1 : 0

  instance_tags = {
    "aws:autoscaling:groupName" = aws_autoscaling_group.worker.name
  }

  depends_on = [aws_autoscaling_group.worker]
}

data "aws_route53_zone" "worker" {
  count = var.zone_name == "" ? 0 : 1

  name = var.zone_name
}

resource "aws_route53_record" "worker" {
  count = var.zone_name == "" ? 0 : var.desired > 0 ? 1 : 0

  name    = var.name
  ttl     = 300
  type    = "A"
  zone_id = data.aws_route53_zone.worker.0.zone_id

  allow_overwrite = true

  records = [
    data.aws_instances.worker.0.public_ips.0
  ]
}

output "public_ip" {
  value = data.aws_instances.worker.0.public_ips
}
