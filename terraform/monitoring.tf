# ─── CloudWatch Monitoring & Alarms ──────────────────────────────────────────

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-eks/cluster"
  retention_in_days = var.cloudwatch_log_retention

  tags = {
    Name = "${var.project_name}-eks-logs"
  }
}

# CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors EKS cluster CPU utilization"
  alarm_actions       = []

  dimensions = {
    ClusterName = "${var.project_name}-eks"
  }

  tags = {
    Name = "${var.project_name}-high-cpu-alarm"
  }
}

# Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "${var.project_name}-high-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "This metric monitors EKS cluster memory utilization"
  alarm_actions       = []

  dimensions = {
    ClusterName = "${var.project_name}-eks"
  }

  tags = {
    Name = "${var.project_name}-high-memory-alarm"
  }
}

# Node Count Alarm
resource "aws_cloudwatch_metric_alarm" "node_count" {
  alarm_name          = "${var.project_name}-node-count-warning"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_count"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.node_group_min_size
  alarm_description   = "This metric monitors EKS cluster node count"
  alarm_actions       = []

  dimensions = {
    ClusterName = "${var.project_name}-eks"
  }

  tags = {
    Name = "${var.project_name}-node-count-alarm"
  }
}

# Pod Count Alarm
resource "aws_cloudwatch_metric_alarm" "pod_count" {
  alarm_name          = "${var.project_name}-pod-count-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "pod_count"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = var.hpa_max_replicas * 0.8
  alarm_description   = "This metric monitors pod count in the cluster"
  alarm_actions       = []

  dimensions = {
    ClusterName = "${var.project_name}-eks"
  }

  tags = {
    Name = "${var.project_name}-pod-count-alarm"
  }
}

# Load Balancer 5XX Errors
resource "aws_cloudwatch_metric_alarm" "lb_5xx_errors" {
  alarm_name          = "${var.project_name}-lb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors 5XX errors from the load balancer"
  alarm_actions       = []

  tags = {
    Name = "${var.project_name}-lb-5xx-errors"
  }
}

# Request Count Alarm
resource "aws_cloudwatch_metric_alarm" "request_count" {
  alarm_name          = "${var.project_name}-high-request-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RequestCount"
  namespace           = "AWS/ELB"
  period              = 300
  statistic           = "Average"
  threshold           = 1000
  alarm_description   = "This metric monitors high request count on the load balancer"
  alarm_actions       = []

  tags = {
    Name = "${var.project_name}-high-request-count"
  }
}
