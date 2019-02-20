resource "aws_ecr_repository" "this" {
  name = "sample"

  lifecycle {
    ignore_changes = ["name"]
  }
}
