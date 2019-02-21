module "vpc" {
  source = "./modules/vpc"
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

module "ecs" {
  source = "./modules/ecs"

  sg_id                     = "${module.security_group.sg_id}"
  private_subnets           = "${module.vpc.private_subnets}"
  lb_arn                    = "${module.nlb.lb_arn}"
  lb_target_group_id        = "${module.nlb.lb_target_group_id}"
  lb_target_group_blue_arn  = "${module.nlb.lb_target_group_arn}"
  lb_target_group_green_arn = "${module.nlb.lb_target_group_2_arn}"
}

# module "aurora" {
#   source = "./modules/aurora"

#   vpc_id          = "${module.vpc.vpc_id}"
#   vpc_cidr_block  = "${module.vpc.vpc_cidr_block}"
#   private_subnets = "${module.vpc.private_subnets}"
#   time_zone       = "Asia/Tokyo"
# }

module "ecr" {
  source = "./modules/ecr"
}

module "code_deploy" {
  source = "./modules/code_deploy"

  lb_listener_arn            = "${module.ecs.lb_listener_arn}"
  lb_target_group_blue_name  = "${module.nlb.lb_target_group_name}"
  lb_target_group_green_name = "${module.nlb.lb_target_group_2_name}"
  ecs_cluster_name           = "${module.ecs.ecs_cluster_name}"
  ecs_service_name           = "${module.ecs.ecs_service_name}"
}