resource "random_shuffle" "subnets" {
  input        = var.subnets
  result_count = 1
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

module "ec2" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.2"

  ami                         = data.aws_ami.ubuntu.id
  key_name                    = "id_rsa"
  user_data                   = var.userdata
  subnet_id                   = random_shuffle.subnets.result[0]
  monitoring                  = false
  instance_type               = var.instance_type
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.public_ip

  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = var.volume_size
    }
  ]

  tags = var.tags
}
