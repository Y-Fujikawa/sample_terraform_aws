resource "aws_instance" "sandbox" {
  count                       = "${lookup(var.ec2_config, "count")}"
  ami                         = "${lookup(var.ec2_config, "ami")}"
  instance_type               = "${lookup(var.ec2_config, "instance_type")}"
  vpc_security_group_ids      = ["${aws_security_group.web.id}"]
  subnet_id                   = "${aws_subnet.public-a.id}"
  associate_public_ip_address = "true"
  key_name                    = "${aws_key_pair.auth.id}"

  tags {
    Name = "${format("sandbox-%02d", count.index + 1)}"
  }
}
