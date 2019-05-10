variable "service_name" {}

variable "domain_bi" {}

variable "vpc_id" {}

variable "sg_id" {}

variable "public_subnets" {
  type = "list"
}

variable "private_subnets" {
  type = "list"
}
