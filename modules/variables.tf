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

variable "key_name" {
  description = "Desired name of AWS key pair"
}

variable "public_key_path" {
  description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.

Example: ~/.ssh/sample.pub
DESCRIPTION
}
