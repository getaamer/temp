module "efs" {
  source        = "terraform-aws-modules/efs/aws"
  version       = "1.2.0"
  access_points = var.access_points
  tags          = var.tags
}
