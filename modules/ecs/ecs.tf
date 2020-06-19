resource "aws_ecs_cluster" "ecs_cluster" {
  name = "web_cluster"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_iam_role_policy" "this" {
  name = "ecs_ssm_policy"
  role = "${data.aws_iam_role.ecs_task_execution_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_ecs_task_definition" "web" {
  family                   = "web"
  container_definitions    = "${file("./task/container_definitions.json")}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"
}

data "aws_acm_certificate" "acm" {
  domain = "${var.domain}"
}

# ECS ServiceはLBがないと設定できないため、ここで定義する
resource "aws_lb_listener" "https_listener_blue" {
  load_balancer_arn = "${var.lb_arn}"
  protocol          = "HTTPS"
  port              = 443
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.acm.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${var.lb_target_group_blue_arn}"
  }

  lifecycle {
    ignore_changes = ["default_action"]
  }
}

# Blue/Green Deployするためにもう1つ必要
resource "aws_lb_listener" "https_listener_green" {
  load_balancer_arn = "${var.lb_arn}"
  protocol          = "HTTPS"
  port              = 8443
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.acm.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${var.lb_target_group_blue_arn}"
  }

  lifecycle {
    ignore_changes = ["default_action"]
  }
}

# Web
resource "aws_ecs_service" "web_service" {
  name             = "web_service"
  cluster          = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition  = "${aws_ecs_task_definition.web.arn}"
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  # ヘルスチェックの猶予期間を30分間で設定
  health_check_grace_period_seconds = 1800

  network_configuration {
    security_groups = ["${var.sg_id}"]
    subnets         = ["${var.private_subnets}"]
  }

  load_balancer {
    target_group_arn = "${var.lb_target_group_id}"
    container_name   = "web"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [
    "aws_lb_listener.https_listener_blue",
  ]

  # FYI https://github.com/terraform-providers/terraform-provider-aws/issues/7001
  lifecycle {
    ignore_changes = ["load_balancer", "task_definition"]
  }
}
