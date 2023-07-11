resource "aws_efs_file_system" "efs" {
  creation_token   = "efs-dev"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  lifecycle_policy { transition_to_ia = "AFTER_30_DAYS" }
  tags = merge(var.tags, { Name = "dev-efs" })
}

resource "aws_efs_mount_target" "mount_targets" {
  count           = var.subnets
  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = var.subnet_id[count.index]
  security_groups = [var.efs-sg.id]
}
