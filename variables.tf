provider "aws" {
  region = "us-east-1" # 米国東部（バージニア北部）
}

variable "ec2_config" {
  type = "map" #省略化

  default = {
    count         = 1
    ami           = "ami-0b86cfbff176b7d3a" # Ubuntu 18.04 LTS official ami
    instance_type = "t2.micro"
  }
}
