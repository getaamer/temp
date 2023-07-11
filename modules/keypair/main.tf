resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = var.key_name
  public_key = tls_private_key.pk.public_key_openssh
}

resource "local_file" "pem" {
  content         = tls_private_key.pk.private_key_pem
  filename        = "temp/${var.key_name}.pem"
  file_permission = "0700"
}

resource "local_file" "pub" {
  content         = aws_key_pair.kp.public_key
  filename        = "temp/${var.key_name}.pub"
  file_permission = "0700"
}