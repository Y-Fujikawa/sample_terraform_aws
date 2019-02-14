resource "aws_ecs_cluster" "web-cluster" {
  name = "web-cluster"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
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

# ECS ServiceはLBがないと設定できないため、ここで定義する
resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${var.lb_arn}"
  protocol          = "TCP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = "${var.lb_target_group_arn}"
  }
}

resource "aws_ecs_service" "web-service" {
  name            = "web-service"
  cluster         = "${aws_ecs_cluster.web-cluster.id}"
  task_definition = "${aws_ecs_task_definition.web.arn}"
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${var.sg_id}"]
    subnets         = ["${var.private_subnets}"]
  }

  load_balancer {
    target_group_arn = "${var.lb_target_group_id}"
    container_name   = "web"
    container_port   = 80
  }

  depends_on = [
    "aws_lb_listener.listener",
  ]
}
