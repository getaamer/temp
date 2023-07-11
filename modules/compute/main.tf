module "ec2-instance" {
  count     = var.instance_count
  source    = "terraform-aws-modules/ec2-instance/aws"
  name      = var.instance_name
  version   = "~> 5.2.1"
  user_data = var.instance_name == "ansible" ? file("${path.module}/userdata.tpl") : file("${path.module}/userdata.sh")

  availability_zone = var.azs

  tags = merge(var.tags, {
    Name = "${var.instance_name}${count.index + 1}"
  })
}
