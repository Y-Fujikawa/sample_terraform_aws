output "alb_arn" {
  value       = "${aws_lb.this.arn}"
}

output "lb_target_group_id" {
  value = "${aws_lb_target_group.target_group.id}"
}

output "listener_arn" {
  value       = "${aws_lb_listener.listener.arn}"
}
