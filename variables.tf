provider "aws" {
  region  = "us-east-1" # 米国東部（バージニア北部）
  version = "~> 2.0"
}

variable "service_name" {
  default = "sample"
}

variable "domain" {
  default = ""
}

# DB
variable "instance_class" {
  default = ""
}

variable "time_zone" {
  default = "Asia/Tokyo"
}
