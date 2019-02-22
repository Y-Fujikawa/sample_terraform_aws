resource "aws_ecr_repository" "this" {
  name = "sample"

  lifecycle {
    create_before_destroy = true
  }
}
