resource "aws_security_group" "sg" {
  for_each    = var.config
  name        = "${each.key}-sg"
  description = "The security group for ${each.key}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = each.value.ports[*]
    content {
      from_port   = ingress.value.from
      to_port     = ingress.value.to
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.source]
      description = ingress.value.description
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, { "Name" = "${each.key}-sg" })
}