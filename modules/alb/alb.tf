resource "aws_lb" "this" {
  name                       = "sample-lb"
  load_balancer_type         = "application"
  internal                   = false
  enable_deletion_protection = false
  security_groups            = ["${var.sg_id}"]
  subnets                    = ["${var.public_subnets}"]

  # TODO LBの設定ができたらログをS3に転送する
  # access_logs {
  #     bucket  = "${aws_s3_bucket.lb_logs.bucket}"
  #     prefix  = "sample-lb"
  #     enabled = true
  # }

  tags = {
    Environment = "${terraform.workspace}"
  }
}

# ECSインスタンスに接続するターゲットグループ
# Blue/Greenデプロイとカナリアリリースのためターゲットグループを2つ用意する
resource "aws_lb_target_group" "target_group_blue" {
  name                 = "sample-lb-tg-blue"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  target_type          = "ip"
  deregistration_delay = "10"

  health_check {
    interval            = 30
    path                = "/index.html"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

resource "aws_lb_target_group" "target_group_green" {
  name                 = "sample-lb-tg-green"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = "${var.vpc_id}"
  target_type          = "ip"
  deregistration_delay = "10"

  health_check {
    interval            = 30
    path                = "/index.html"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}
