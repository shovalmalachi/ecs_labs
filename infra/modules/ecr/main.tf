resource "aws_ecr_repository" "this" {
  name         = var.repository_name
  force_delete = var.force_delete

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}