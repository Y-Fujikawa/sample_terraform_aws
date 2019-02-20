resource "aws_lb" "this" {
  name                       = "sample-lb"
  load_balancer_type         = "network"
  internal                   = false
  enable_deletion_protection = false
  subnets                    = ["${var.public_subnets}"]

  # TODO LBの設定ができたらログをS3に転送する
  # access_logs {
  #   bucket  = "${aws_s3_bucket.lb_logs.bucket}"
  #   prefix  = "sample-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "dev"
  }
}

# ECSインスタンス
resource "aws_lb_target_group" "target_group" {
  name                 = "sample-lb-tg"
  port                 = 80
  protocol             = "TCP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "10"
  target_type          = "ip"

  # NLB指定時に必要な設定
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}

# Blue/Green Deployするために必要
resource "aws_lb_target_group" "target_group_2" {
  name                 = "sample-lb-tg-2"
  port                 = 80
  protocol             = "TCP"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "10"
  target_type          = "ip"

  # NLB指定時に必要な設定
  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}
