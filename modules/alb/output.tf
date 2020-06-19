output "lb_arn" {
  value = "${aws_lb.this.arn}"
}

output "lb_target_group_blue_id" {
  value = "${aws_lb_target_group.target_group_blue.id}"
}

output "lb_target_group_blue_arn" {
  value = "${aws_lb_target_group.target_group_blue.arn}"
}

output "lb_target_group_blue_name" {
  value = "${aws_lb_target_group.target_group_blue.name}"
}

output "lb_target_group_green_arn" {
  value = "${aws_lb_target_group.target_group_green.arn}"
}

output "lb_target_group_green_name" {
  value = "${aws_lb_target_group.target_group_green.name}"
}
