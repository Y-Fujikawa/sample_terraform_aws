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
# module "alb" {
#   source = "./modules/alb"
#
#   vpc_id         = "${module.vpc.vpc_id}"
#   public_subnets = "${module.vpc.public_subnets}"
#   sg_id          = "${module.security_group.sg_id}"
# }

#########################
# Network LoadBalancer
#########################
module "nlb" {
  source = "./modules/nlb"

  vpc_id         = "${module.vpc.vpc_id}"
  public_subnets = "${module.vpc.public_subnets}"
}

#########################
# Cloud Front
#########################
module "cloudfront" {
  source = "./modules/cloudfront"

  domain   = "${var.domain}"
  dns_name = "${module.nlb.dns_name}"
}

#########################
# ECS
#########################
module "ecs" {
  source = "./modules/ecs"

  domain                    = "${var.domain}"
  sg_id                     = "${module.security_group.sg_id}"
  private_subnets           = "${module.vpc.private_subnets}"
  lb_arn                    = "${module.nlb.lb_arn}"
  lb_target_group_id        = "${module.nlb.lb_target_group_blue_id}"
  lb_target_group_blue_arn  = "${module.nlb.lb_target_group_blue_arn}"
  lb_target_group_green_arn = "${module.nlb.lb_target_group_green_arn}"
}

#########################
# Aurora MySQL
#########################
module "aurora" {
  source = "./modules/aurora"

  service_name    = "${var.service_name}"
  vpc_id          = "${module.vpc.vpc_id}"
  vpc_cidr_block  = "${module.vpc.vpc_cidr_block}"
  private_subnets = "${module.vpc.private_subnets}"
  instance_class  = "${var.instance_class}"
  time_zone       = "${var.time_zone}"
}

# TODO: lifecycleがうまく機能しないため手動作成にする
# module "ecr" {
#   source = "./modules/ecr"
# }

#########################
# Codepipeline
#########################
module "code_pipeline" {
  source = "./modules/code_pipeline"

  service_name                = "${var.service_name}"
  vpc_id                      = "${module.vpc.vpc_id}"
  private_subnets             = "${module.vpc.private_subnets}"
  lb_https_listener_blue_arn  = "${module.ecs.lb_https_listener_blue_arn}"
  lb_https_listener_green_arn = "${module.ecs.lb_https_listener_green_arn}"
  lb_target_group_blue_name   = "${module.nlb.lb_target_group_blue_name}"
  lb_target_group_green_name  = "${module.nlb.lb_target_group_green_name}"
  ecs_cluster_name            = "${module.ecs.ecs_cluster_name}"
  ecs_service_name            = "${module.ecs.ecs_service_name}"
  db_security_group_id        = "${module.aurora.db_security_group_id}"
  db_host                     = "${module.aurora.db_host}"
  rails_env                   = "${var.rails_env}"
}

#########################
# Auto Scale Setting
#########################
module "auto_scale_setting" {
  source = "./modules/auto_scale_setting"

  service_name     = "${var.service_name}"
  ecs_cluster_name = "${module.ecs.ecs_cluster_name}"
  ecs_service_name = "${module.ecs.ecs_service_name}"
}

#########################
# Redash
#########################
module "redash" {
  source = "./modules/redash"

  service_name      = "${var.service_name}"
  domain_bi         = "${var.domain_bi}"
  vpc_id            = "${module.vpc.vpc_id}"
  sg_id             = "${module.security_group.sg_id}"
  public_subnets    = "${module.vpc.public_subnets}"
  private_subnets   = "${module.vpc.private_subnets}"
}
