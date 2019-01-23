resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"

    tags {
        Name = "${format("sandbox-%02d", count.index + 1)}"
    }
}
