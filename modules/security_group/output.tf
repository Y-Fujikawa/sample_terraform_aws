output "sg_id" {
  description = "セキュリティグループのID"
  value       = "${aws_security_group.web.id}"
}
