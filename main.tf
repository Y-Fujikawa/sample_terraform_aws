module "vpc" {
  source = "./modules/vpc"
}

module "security_group" {
  source = "./modules/security_group"

  vpc_id = "${module.vpc.vpc_id}"
}

module "elb" {
  source = "./modules/elb"

  vpc_id         = "${module.vpc.vpc_id}"
  public_subnets = "${module.vpc.public_subnets}"
  sg_id          = "${module.security_group.sg_id}"
}

module "ecs" {
  source = "./modules/ecs"

  sg_id              = "${module.security_group.sg_id}"
  private_subnets    = "${module.vpc.private_subnets}"
  lb_target_group_id = "${module.elb.lb_target_group_id}"
}
