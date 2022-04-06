# aws_security_group

resource "aws_security_group" "worker" {
  name = format("%s-worker", var.name)

  vpc_id = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "worker_worker" {
  description              = format("Allow to workers")
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.worker.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker_ssh" {
  description       = format("Allow to communicate ssh")
  from_port         = 22
  to_port           = 22
  security_group_id = aws_security_group.worker.id
  protocol          = "tcp"
  cidr_blocks       = var.allow_ip_address
  type              = "ingress"
}

resource "aws_security_group_rule" "worker_8080" {
  description       = format("Allow to communicate 8080-8100")
  from_port         = 8080
  to_port           = 8100
  security_group_id = aws_security_group.worker.id
  protocol          = "tcp"
  cidr_blocks       = var.allow_ip_address
  type              = "ingress"
}

resource "aws_security_group_rule" "worker_8888" {
  description       = format("Allow to communicate 8888")
  from_port         = 8888
  to_port           = 8888
  security_group_id = aws_security_group.worker.id
  protocol          = "tcp"
  cidr_blocks       = var.allow_ip_address
  type              = "ingress"
}
