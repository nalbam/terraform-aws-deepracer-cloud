# aws_lb

resource "aws_lb" "http" {
  name                             = var.name
  internal                         = false
  load_balancer_type               = "network"
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  subnets                          = local.subnet_ids

  tags = local.tags
}

resource "aws_lb_target_group" "http" {
  count = length(var.ports)

  name        = format("%s-%s", var.name, var.ports[count.index])
  target_type = "instance"
  port        = var.ports[count.index]
  protocol    = "TCP"
  vpc_id      = local.vpc_id

  deregistration_delay = 10

  tags = merge(
    local.tags,
    {
      "Name" = format("%s-%s", var.name, var.ports[count.index])
    },
  )
}

resource "aws_lb_listener" "http" {
  count = length(var.ports)

  load_balancer_arn = aws_lb.http.arn
  port              = var.ports[count.index]
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http[count.index].arn
  }
}
