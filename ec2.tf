resource "aws_instance" "sandbox" {
    count                       = "${lookup(var.ec2_config, "count")}"
    ami                         = "${lookup(var.ec2_config, "ami")}"
    instance_type               = "${lookup(var.ec2_config, "instance_type")}"
    vpc_security_group_ids      = ["${aws_security_group.sample_security_group.id}"]
    subnet_id                   = "${aws_subnet.public-a.id}"
    associate_public_ip_address = "true"

    tags {
        Name = "${format("sandbox-%02d", count.index + 1)}"
    }
}
