resource "aws_ecs_cluster" "web-cluster" {
  name = "web-cluster"
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

data "aws_acm_certificate" "sample_acm" {
  domain = "${var.domain}"
}

# ECS ServiceはLBがないと設定できないため、ここで定義する
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = "${var.lb_arn}"
  protocol          = "TLS"
  port              = 443
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.sample_acm.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${var.lb_target_group_blue_arn}"
  }

  lifecycle {
    ignore_changes = ["default_action"]
  }
}

# Blue/Green Deployするためにもう1つ必要
resource "aws_lb_listener" "https_listener2" {
  load_balancer_arn = "${var.lb_arn}"
  protocol          = "TLS"
  port              = 8443
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${data.aws_acm_certificate.sample_acm.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${var.lb_target_group_blue_arn}"
  }

  lifecycle {
    ignore_changes = ["default_action"]
  }
}

# Web
resource "aws_ecs_service" "web-service" {
  name                              = "web-service"
  cluster                           = "${aws_ecs_cluster.web-cluster.id}"
  task_definition                   = "${aws_ecs_task_definition.web.arn}"
  desired_count                     = 2
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 300

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
    "aws_lb_listener.https_listener",
  ]

  # FYI https://github.com/terraform-providers/terraform-provider-aws/issues/7001
  lifecycle {
    ignore_changes = ["load_balancer", "task_definition"]
  }
}

# Migrate
resource "aws_ecs_task_definition" "migrate" {
  family                   = "migrate"
  container_definitions    = "${file("./task/container_definitions.json")}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"
}

resource "aws_ecs_service" "migrate-service" {
  name                              = "migrate-service"
  cluster                           = "${aws_ecs_cluster.web-cluster.id}"
  task_definition                   = "${aws_ecs_task_definition.migrate.arn}"
  desired_count                     = 0
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 0

  network_configuration {
    security_groups = ["${var.sg_id}"]
    subnets         = ["${var.private_subnets}"]
  }

  load_balancer {
    target_group_arn = "${var.lb_target_group_id}"
    container_name   = "migrate"
    container_port   = 80
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  depends_on = [
    "aws_ecs_task_definition.migrate",
  ]

  # FYI https://github.com/terraform-providers/terraform-provider-aws/issues/7001
  lifecycle {
    ignore_changes = ["load_balancer", "task_definition"]
  }
}
