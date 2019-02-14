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

  sg_id               = "${module.security_group.sg_id}"
  private_subnets     = "${module.vpc.private_subnets}"
  lb_arn              = "${module.nlb.lb_arn}"
  lb_target_group_id  = "${module.nlb.lb_target_group_id}"
  lb_target_group_arn = "${module.nlb.lb_target_group_arn}"
}
