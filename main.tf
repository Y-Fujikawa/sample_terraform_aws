provider "aws" {
  region  = "${var.region}"
  version = "~> 2.0"
}

terraform {
  # tfstateをローカルマシンで管理する場合、こちらを使う  # その際「terraform init -reconfigure」を実行する  # backend "local" {}

  backend "s3" {}
}

#########################
# VPC
#########################
module "vpc" {
  source = "./modules/vpc"

  service_name = "${var.service_name}"
}

#########################
# Security Group
#########################
module "security_group" {
  source = "./modules/security_group"

  vpc_id = "${module.vpc.vpc_id}"
}

#########################
# Application LoadBalancer
#########################
module "alb" {
  source = "./modules/alb"

  vpc_id         = "${module.vpc.vpc_id}"
  public_subnets = "${module.vpc.public_subnets}"
  sg_id          = "${module.security_group.sg_id}"
}

#########################
# ECS
#########################
module "ecs" {
  source = "./modules/ecs"

  domain                    = "${var.domain}"
  sg_id                     = "${module.security_group.sg_id}"
  private_subnets           = "${module.vpc.private_subnets}"
  lb_arn                    = "${module.alb.lb_arn}"
  lb_target_group_id        = "${module.alb.lb_target_group_blue_id}"
  lb_target_group_blue_arn  = "${module.alb.lb_target_group_blue_arn}"
  lb_target_group_green_arn = "${module.alb.lb_target_group_green_arn}"
}
