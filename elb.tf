resource "aws_lb" "lb" {
    name                       = "sample-lb"
    load_balancer_type         = "application"
    internal                   = false
    enable_deletion_protection = false
    security_groups            = ["${aws_security_group.lb.id}"]
    subnets                    = ["${aws_subnet.public-a.*.id}", "${aws_subnet.public-c.*.id}"]

    # TODO LBの設定ができたらログをS3に転送する
    # access_logs {
    #     bucket  = "${aws_s3_bucket.lb_logs.bucket}"
    #     prefix  = "sample-lb"
    #     enabled = true
    # }

    tags = {
        Environment = "development"
    }
}

resource "aws_lb_target_group" "lb" {
    name     = "sample-lb-tg"
    port     = 80
    protocol = "HTTP"
    vpc_id   = "${aws_vpc.sample_vpc.id}"

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

resource "aws_lb_target_group_attachment" "lb" {
    target_group_arn = "${aws_lb_target_group.lb.arn}"
    target_id        = "${aws_instance.sandbox.id}"
    port             = 80
}

resource "aws_lb_listener" "lb" {
    load_balancer_arn = "${aws_lb.lb.arn}"
    port              = 80

    default_action {
        type             = "forward"
        target_group_arn = "${aws_lb_target_group.lb.arn}"
    }
}