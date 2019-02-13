output "alb_arn" {
  value       = "${aws_lb.this.arn}"
}

output "listener_arn" {
  value       = "${aws_lb_listener.listener.arn}"
}
