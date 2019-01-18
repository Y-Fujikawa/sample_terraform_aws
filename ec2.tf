resource "aws_instance" "sandbox" {
  count = 2
  ami = "ami-0b86cfbff176b7d3a" # Ubuntu 18.04 LTS official ami
  instance_type = "t2.micro"

  tags {
    Name = "${format("modified sandbox-%02d", count.index + 1)}"
  }
}
