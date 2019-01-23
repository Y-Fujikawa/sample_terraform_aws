resource "aws_instance" "sandbox" {
    count = "${lookup(var.ec2_config, "count")}"
    ami = "${lookup(var.ec2_config, "ami")}"
    instance_type = "${lookup(var.ec2_config, "instance_type")}"

    tags {
      Name = "${format("sandbox-%02d", count.index + 1)}"
    }
}
