resource "aws_ecs_cluster" "web-cluster" {
  name = "web-cluster"
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "web" {
  family                   = "web"
  container_definitions    = "${file("task/web.json")}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = "${data.aws_iam_role.ecs_task_execution_role.arn}"
}

resource "aws_ecs_service" "web-service" {
  name            = "web-service"
  cluster         = "${aws_ecs_cluster.web-cluster.id}"
  task_definition = "${aws_ecs_task_definition.web.arn}"
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.web.id}"]
    subnets         = ["${aws_subnet.public-a.id}"]

    # Fargateリポジトリ以外からコンテナイメージ取得に必要
    # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task_cannot_pull_image.html
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.lb-ecs.id}"
    container_name   = "web"
    container_port   = 80
  }

  depends_on = [
    "aws_lb_listener.lb-ecs",
  ]
}
