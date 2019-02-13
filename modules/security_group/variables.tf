provider "aws" {
  region = "us-east-1" # 米国東部（バージニア北部）
}

variable "vpc_id" {
  description = "ID of the VPC where to create security group"
  default     = ""
}
