# aws_route53

data "aws_route53_zone" "worker" {
  count = var.zone_name == "" ? 0 : 1

  name = var.zone_name
}

resource "aws_route53_record" "worker" {
  count = var.zone_name == "" ? 0 : var.desired > 0 ? 1 : 0

  name    = var.name
  type    = "A"
  zone_id = data.aws_route53_zone.worker.0.zone_id

  allow_overwrite = true

  alias {
    name                   = aws_lb.http.dns_name
    zone_id                = aws_lb.http.zone_id
    evaluate_target_health = "false"
  }
}

output "domain" {
  value = try(aws_route53_record.worker.0.fqdn, "")
}
