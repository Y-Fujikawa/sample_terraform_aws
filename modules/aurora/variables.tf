variable "service_name" {}

variable "vpc_id" {}

variable "vpc_cidr_block" {}

variable "private_subnets" {
  type = "list"
}

variable "instance_class" {}

variable "time_zone" {}
