output "ec2_redash_name" {
  value = "${lookup(aws_instance.redash.tags, "Name")}"
}
