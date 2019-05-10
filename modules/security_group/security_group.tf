resource "aws_security_group" "lb" {
  name        = "${terraform.workspace}_sample_sg_lb"
  description = "${terraform.workspace}_sample_sg_lb"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}_sample_sg_lb"
  }
}

resource "aws_security_group" "web" {
  name        = "${terraform.workspace}_sample_sg_web"
  description = "${terraform.workspace}_sample_sg_web"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.lb.id}"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.lb.id}"]
  }

  # Fargateリポジトリ以外からコンテナイメージ取得に必要
  # https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task_cannot_pull_image.html
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${terraform.workspace}_sample_sg_web"
  }
}
