output "lb_listener_arn" {
  value = "${aws_lb_listener.listener.arn}"
}

output "lb_listener_2_arn" {
  value = "${aws_lb_listener.listener2.arn}"
}

output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.web-cluster.name}"
}

output "ecs_service_name" {
  value = "${aws_ecs_service.web-service.name}"
}
