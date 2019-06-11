#####################################
# Auto Scale Setting
#####################################
# CPU
resource "aws_cloudwatch_metric_alarm" "service_cpu_sacle_out_alerm" {
  alarm_name          = "${terraform.workspace}-${var.service_name}-ECSService-CPU-Utilization-High-50"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 180
  statistic           = "Average"
  threshold           = 50

  dimensions {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${var.ecs_service_name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.cpu_scale_out.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_sacle_in_alerm" {
  alarm_name          = "${terraform.workspace}-${var.service_name}-ECSService-CPU-Utilization-Low-25"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 180
  statistic           = "Average"
  threshold           = 25

  dimensions {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${var.ecs_service_name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.cpu_scale_in.arn}"]
}

resource "aws_appautoscaling_target" "ecs_service_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster_name}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 1
  max_capacity       = 2
}

resource "aws_appautoscaling_policy" "cpu_scale_out" {
  name               = "${terraform.workspace}-${var.service_name}-cpu-scale-out"
  resource_id        = "${aws_appautoscaling_target.ecs_service_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_service_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_service_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.ecs_service_target"]
}

resource "aws_appautoscaling_policy" "cpu_scale_in" {
  name               = "${terraform.workspace}-${var.service_name}-cpu-scale-in"
  resource_id        = "${aws_appautoscaling_target.ecs_service_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_service_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_service_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.ecs_service_target"]
}

# Memory
resource "aws_cloudwatch_metric_alarm" "service_memory_sacle_out_alerm" {
  alarm_name          = "${terraform.workspace}-${var.service_name}-ECSService-Memory-Utilization-High-50"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 180
  statistic           = "Average"
  threshold           = 50

  dimensions {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${var.ecs_service_name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.memory_scale_out.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "service_memory_sacle_in_alerm" {
  alarm_name          = "${terraform.workspace}-${var.service_name}-ECSService-Memory-Utilization-Low-25"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 180
  statistic           = "Average"
  threshold           = 25

  dimensions {
    ClusterName = "${var.ecs_cluster_name}"
    ServiceName = "${var.ecs_service_name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.memory_scale_in.arn}"]
}

resource "aws_appautoscaling_policy" "memory_scale_out" {
  name               = "${terraform.workspace}-${var.service_name}-memory-scale-out"
  resource_id        = "${aws_appautoscaling_target.ecs_service_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_service_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_service_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.ecs_service_target"]
}

resource "aws_appautoscaling_policy" "memory_scale_in" {
  name               = "${terraform.workspace}-${var.service_name}-memory-scale-in"
  resource_id        = "${aws_appautoscaling_target.ecs_service_target.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ecs_service_target.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ecs_service_target.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.ecs_service_target"]
}
