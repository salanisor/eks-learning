# ── SNS topic for alarm notifications ────────────────────────────────────────
resource "aws_sns_topic" "alarms" {
  name = "${var.cluster_name}-alarms"

  tags = {
    Name = "${var.cluster_name}-alarms"
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.sns_email
}

# ── Node CPU alarm ────────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  alarm_name          = "${var.cluster_name}-node-cpu-high"
  alarm_description   = "Node CPU utilization is above ${var.cpu_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name = "${var.cluster_name}-node-cpu-high"
  }
}

# ── Node memory alarm ─────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  alarm_name          = "${var.cluster_name}-node-memory-high"
  alarm_description   = "Node memory utilization is above ${var.memory_threshold}%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name = "${var.cluster_name}-node-memory-high"
  }
}

# ── Pod restart alarm ─────────────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "pod_restarts_high" {
  alarm_name          = "${var.cluster_name}-pod-restarts-high"
  alarm_description   = "Pod restart count is elevated — possible crash loop"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name = "${var.cluster_name}-pod-restarts-high"
  }
}

# ── Cluster failed pod alarm ──────────────────────────────────────────────────
resource "aws_cloudwatch_metric_alarm" "cluster_failed_pods" {
  alarm_name          = "${var.cluster_name}-failed-pods"
  alarm_description   = "Pods are in failed state"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "cluster_failed_node_count"
  namespace           = "ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.alarms.arn]
  ok_actions          = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = {
    Name = "${var.cluster_name}-failed-pods"
  }
}