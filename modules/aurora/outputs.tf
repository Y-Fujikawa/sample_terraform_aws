output "db_security_group_id" {
  value = "${aws_security_group.aurora.id}"
}

output "db_host" {
  value = "${aws_rds_cluster.this.endpoint}"
}
