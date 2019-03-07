output "lb_https_listener_arn" {
  value = "${aws_lb_listener.https_listener.arn}"
}

output "lb_https_listener_2_arn" {
  value = "${aws_lb_listener.https_listener2.arn}"
}

output "ecs_cluster_name" {
  value = "${aws_ecs_cluster.web-cluster.name}"
}

output "ecs_service_name" {
  value = "${aws_ecs_service.web-service.name}"
}

output "ecs_service_name_migrate" {
  value = "${aws_ecs_service.migrate-service.name}"
}
