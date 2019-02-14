variable "sg_id" {}

variable "private_subnets" {
  type = "list"
}

variable "lb_arn" {}

variable "lb_target_group_id" {}

variable "lb_target_group_arn" {}
