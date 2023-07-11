module "ec2-instance" {
  version = "~> 5.2.1"
  source  = "terraform-aws-modules/ec2-instance/aws"

  count                  = var.instance_count
  name                   = var.instance_name
  subnet_id              = element(var.subnets, count.index)
  vpc_security_group_ids = var.security_group_ids
  instance_type          = var.instance_type
  availability_zone      = var.azs

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.volume_size
    }
  ]

  tags = merge(var.tags, { Name = "${var.instance_name}${count.index + 1}" })
}
