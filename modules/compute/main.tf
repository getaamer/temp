module "ec2-instance" {
  count             = var.instance_count
  source            = "terraform-aws-modules/ec2-instance/aws"
  version           = "~> 5.2.1"
  name              = var.instance_name
  instance_type     = var.instance_type
  availability_zone = var.azs
  key_name          = var.key_name

  tags = merge(var.tags, {
    Name = "${var.instance_name}${count.index + 1}"
  })
}
