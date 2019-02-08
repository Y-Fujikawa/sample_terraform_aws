# VPCの設定
resource "aws_vpc" "sample_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags {
    Name = "${format("sandbox-%02d", count.index + 1)}"
  }
}

# Public Subnetの作成
resource "aws_subnet" "public-a" {
  vpc_id     = "${aws_vpc.sample_vpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags {
    Name = "${format("sandbox-%02d", count.index + 1)}"
  }
}

resource "aws_subnet" "public-c" {
  vpc_id     = "${aws_vpc.sample_vpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1c"

  tags {
    Name = "${format("sandbox-%02d", count.index + 1)}"
  }
}

# Private Subnetの作成
resource "aws_subnet" "private-a" {
  vpc_id     = "${aws_vpc.sample_vpc.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags {
    Name = "${format("sandbox-%02d", count.index + 1)}"
  }
}

# Private Subnetの追加
resource "aws_subnet" "private-c" {
  vpc_id     = "${aws_vpc.sample_vpc.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1c"

  tags {
    Name = "${format("sandbox-%02d", count.index + 1)}"
  }
}

# Internet Gatewayの作成
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.sample_vpc.id}"

   tags {
     Name = "${format("sandbox-%02d", count.index + 1)}"
   }
 }

# NATゲートウェイのためにElastic IPを作成
resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_nat_gateway" "gw" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id     = "${aws_subnet.public-a.id}"
}

# Root Tableの作成
resource "aws_route_table" "public-route" {
  vpc_id = "${aws_vpc.sample_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table" "private-route-a" {
  vpc_id = "${aws_vpc.sample_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }
}

resource "aws_route_table" "private-route-c" {
  vpc_id = "${aws_vpc.sample_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }
}

# Root Tableの追加
resource "aws_route_table_association" "public-a" {
  route_table_id = "${aws_route_table.public-route.id}"
  subnet_id      = "${aws_subnet.public-a.id}"
}

resource "aws_route_table_association" "public-c" {
  route_table_id = "${aws_route_table.public-route.id}"
  subnet_id      = "${aws_subnet.public-c.id}"
}

resource "aws_route_table_association" "private-a" {
  route_table_id = "${aws_route_table.private-route-a.id}"
  subnet_id      = "${aws_subnet.private-a.id}"
}

resource "aws_route_table_association" "private-c" {
  route_table_id = "${aws_route_table.private-route-c.id}"
  subnet_id      = "${aws_subnet.private-c.id}"
}
