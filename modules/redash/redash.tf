resource "aws_lb" "this" {
  name                       = "${terraform.workspace}-${var.service_name}-redash-alb"
  load_balancer_type         = "application"
  internal                   = false
  enable_deletion_protection = false
  security_groups            = ["${var.sg_id}"]
  subnets                    = ["${var.public_subnets}"]

  tags = {
    Environment = "${terraform.workspace}"
    Service     = "${terraform.workspace}-${var.service_name}-redash"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "${terraform.workspace}-${var.service_name}-redash-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    protocol            = "HTTP"
    path                = "/login"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
  }

  tags = {
    Environment = "${terraform.workspace}"
    Service     = "${terraform.workspace}-${var.service_name}-redash"
  }
}

data "aws_acm_certificate" "this" {
  domain = "${var.domain_bi}"
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = "${aws_lb.this.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = "${aws_lb.this.arn}"
  protocol          = "HTTPS"
  port              = 443
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.this.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.this.arn}"
  }
}

resource "aws_iam_role" "this" {
  name               = "${terraform.workspace}-${var.service_name}-redash-role"
  description        = "Exec lambda from ssm."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = "${aws_iam_role.this.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_instance_profile" "redash_instance_role" {
    name = "redash_instance_role"
    roles = ["${aws_iam_role.this.name}"]
}

# EC2インスタンス
resource "aws_instance" "redash" {
  # https://redash.io/help/open-source/setup
  ami                    = "ami-0c654c3ab463d22f6"
  instance_type          = "t2.small"
  vpc_security_group_ids = ["${var.sg_id}"]
  subnet_id              = "${var.private_subnets[0]}"
  iam_instance_profile   = "${aws_iam_instance_profile.redash_instance_role.name}"

  tags = {
    Environment = "${terraform.workspace}"
    Service     = "${terraform.workspace}-${var.service_name}-redash"
    Name        = "${terraform.workspace}-${var.service_name}-redash-ec2"
  }
}

resource "aws_alb_target_group_attachment" "this" {
  target_group_arn = "${aws_lb_target_group.this.arn}"
  target_id        = "${aws_instance.redash.id}"
  port             = 80
}
