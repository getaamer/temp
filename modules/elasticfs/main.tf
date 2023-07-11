resource "aws_efs_file_system" "efs" {
  encrypted        = true
  creation_token   = "efs-dev"
  throughput_mode  = "bursting"
  performance_mode = "generalPurpose"
  lifecycle_policy { transition_to_ia = "AFTER_30_DAYS" }
  tags = merge(var.tags, { Name = "dev-efs" })
}

resource "aws_efs_mount_target" "mount_targets" {
  count           = var.subnets
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_id[count.index]
  security_groups = [var.efs-sg.id]
}
