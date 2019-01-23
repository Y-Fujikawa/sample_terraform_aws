# VPCの設定
resource "aws_vpc" "sample_vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"

    tags {
        Name = "${format("sandbox-%02d", count.index + 1)}"
    }
}

# Public Subnetの作成
resource "aws_subnet" "public-a" {
    vpc_id     = "${aws_vpc.sample_vpc.id}"
    cidr_block = "10.0.1.0/24"

    tags {
        Name = "${format("sandbox-%02d", count.index + 1)}"
    }
}

# Public Subnetの追加
resource "aws_subnet" "public-c" {
    vpc_id     = "${aws_vpc.sample_vpc.id}"
    cidr_block = "10.0.2.0/24"

    tags {
        Name = "${format("sandbox-%02d", count.index + 1)}"
    }
}
