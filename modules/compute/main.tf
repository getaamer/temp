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

locals {
  instances_flat = merge([
    for env, val in var.instances : {
      for idx in range(val["instance_count"]) : "${env}-${idx}" => {
        instance_type = val["instance_type"]
        environment   = val["environment"]
        key_name      = val["key_name"]
        volume_size   = val["volume_size"]
        volume_type   = val["volume_type"]
      }
    }
  ]...)
}

resource "random_shuffle" "subnets" {
  input        = var.subnets
  result_count = length(var.subnets)
}

resource "aws_instance" "this" {
  for_each      = local.instances_flat
  ami           = data.aws_ami.ubuntu.id
  key_name      = each.value.key_name
  subnet_id     = random_shuffle.subnets.result[0]
  instance_type = each.value.instance_type
  root_block_device {
    volume_size = each.value.volume_size
    volume_type = each.value.volume_type
  }
  tags = merge(var.tags, {
    "Name" = "${each.key}"
  })
}
