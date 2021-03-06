variable "service_name" {}

variable "vpc_id" {}

variable "lb_https_listener_blue_arn" {}

variable "lb_https_listener_green_arn" {}

variable "lb_target_group_blue_name" {}

variable "lb_target_group_green_name" {}

variable "ecs_cluster_name" {}

variable "ecs_service_name" {}

variable "db_security_group_id" {}

variable "private_subnets" {
  type = "list"
}

variable "db_host" {}

variable "rails_env" {}
