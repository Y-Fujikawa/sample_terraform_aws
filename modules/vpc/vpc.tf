# VPCの設定
resource "aws_vpc" "this" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Public Subnetの作成
resource "aws_subnet" "public_a" {
  vpc_id            = "${aws_vpc.this.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  lifecycle {
    ignore_changes = ["cidr_block"]
  }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id            = "${aws_vpc.this.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"

  lifecycle {
    ignore_changes = ["cidr_block"]
  }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Private Subnetの作成
resource "aws_subnet" "private_a" {
  vpc_id            = "${aws_vpc.this.id}"
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  lifecycle {
    ignore_changes = ["cidr_block"]
  }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Private Subnetの追加
resource "aws_subnet" "private_c" {
  vpc_id            = "${aws_vpc.this.id}"
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1c"

  lifecycle {
    ignore_changes = ["cidr_block"]
  }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Internet Gatewayの作成
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.this.id}"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# NATゲートウェイのためにElastic IPを作成
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public_a.id}"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Root Tableの作成
resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.this.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route_table" "private_route_a" {
  vpc_id = "${aws_vpc.this.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }

  lifecycle {
    ignore_changes = ["route"]
  }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_route_table" "private_route_c" {
  vpc_id = "${aws_vpc.this.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gw.id}"
  }

  lifecycle {
    ignore_changes = ["route"]
  }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# Root Tableの追加
resource "aws_route_table_association" "public_a" {
  route_table_id = "${aws_route_table.public_route.id}"
  subnet_id      = "${aws_subnet.public_a.id}"
}

resource "aws_route_table_association" "public_c" {
  route_table_id = "${aws_route_table.public_route.id}"
  subnet_id      = "${aws_subnet.public_c.id}"
}

resource "aws_route_table_association" "private_a" {
  route_table_id = "${aws_route_table.private_route_a.id}"
  subnet_id      = "${aws_subnet.private_a.id}"
}

resource "aws_route_table_association" "private_c" {
  route_table_id = "${aws_route_table.private_route_c.id}"
  subnet_id      = "${aws_subnet.private_c.id}"
}
