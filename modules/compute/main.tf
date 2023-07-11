module "ec2-instance" {
  count   = var.instance_count
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2.1"
  name    = var.instance_name

  user_data         = var.instance_name == "ansible" ? file("${path.module}/userdata.tpl") : file("${path.module}/userdata.sh")
  instance_type     = var.instance_type
  availability_zone = var.azs

  root_block_device = [
    {
      volume_type = var.volume_type
      volume_size = var.volume_size
    }
  ]

  tags = merge(var.tags, {
    Name = "${var.instance_name}${count.index + 1}"
  })
}
