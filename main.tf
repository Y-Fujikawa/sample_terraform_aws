provider "aws" {
  region  = "${var.region}"
  version = "~> 2.0"
}

terraform {
  # tfstateをローカルマシンで管理する場合、こちらを使う
  # その際「terraform init -reconfigure」を実行する
  # backend "local" {}

  backend "s3" {}
}

module "vpc" {
  source = "./modules/vpc"

  service_name = "${var.service_name}"
}

module "security_group" {
  source = "./modules/security_group"

  vpc_id = "${module.vpc.vpc_id}"
}

# module "alb" {
#   source = "./modules/alb"
#
#   vpc_id         = "${module.vpc.vpc_id}"
#   public_subnets = "${module.vpc.public_subnets}"
#   sg_id          = "${module.security_group.sg_id}"
# }

module "nlb" {
  source = "./modules/nlb"

  vpc_id         = "${module.vpc.vpc_id}"
  public_subnets = "${module.vpc.public_subnets}"
}

module "cloudfront" {
  source = "./modules/cloudfront"

  domain   = "${var.domain}"
  dns_name = "${module.nlb.dns_name}"
}

module "ecs" {
  source = "./modules/ecs"

  domain                    = "${var.domain}"
  sg_id                     = "${module.security_group.sg_id}"
  private_subnets           = "${module.vpc.private_subnets}"
  lb_arn                    = "${module.nlb.lb_arn}"
  lb_target_group_id        = "${module.nlb.lb_target_group_id}"
  lb_target_group_blue_arn  = "${module.nlb.lb_target_group_arn}"
  lb_target_group_green_arn = "${module.nlb.lb_target_group_2_arn}"
}

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

module "code_pipeline" {
  source = "./modules/code_pipeline"

  lb_https_listener_arn      = "${module.ecs.lb_https_listener_arn}"
  lb_https_listener_2_arn    = "${module.ecs.lb_https_listener_2_arn}"
  lb_target_group_blue_name  = "${module.nlb.lb_target_group_name}"
  lb_target_group_green_name = "${module.nlb.lb_target_group_2_name}"
  ecs_cluster_name           = "${module.ecs.ecs_cluster_name}"
  ecs_service_name           = "${module.ecs.ecs_service_name}"
}
