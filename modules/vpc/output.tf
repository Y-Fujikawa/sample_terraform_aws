output "vpc_id" {
  description = "VPCのID"
  value       = "${aws_vpc.this.id}"
}

output "vpc_cidr_block" {
  description = "VPCのCIDR"
  value       = "${aws_vpc.this.cidr_block}"
}

output "public_subnets" {
  description = "パブリックサブネットのID一覧"
  value       = ["${aws_subnet.public-a.*.id}", "${aws_subnet.public-c.*.id}"]
}

output "private_subnets" {
  description = "プライベートサブネットのID一覧"
  value       = ["${aws_subnet.private-a.*.id}", "${aws_subnet.private-c.*.id}"]
}
