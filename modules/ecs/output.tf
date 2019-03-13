output "lb_https_listener_blue_arn" {
  value = "${aws_lb_listener.https_listener_blue.arn}"
}

output "lb_https_listener_green_arn" {
  value = "${aws_lb_listener.https_listener_green.arn}"
}

output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.web_cluster.name}"
}

output "ecs_service_name" {
  value = "${aws_ecs_service.web_service.name}"
}
