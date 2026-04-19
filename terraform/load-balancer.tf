# ─── Application Load Balancer (ALB) ─────────────────────────────────────────

resource "aws_lb" "jokejolt" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "production"
  enable_http2               = true
  idle_timeout               = 60

  access_logs {
    bucket  = aws_s3_bucket.alb_logs[0].id
    prefix  = "alb-logs"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-alb"
    Type = "Application Load Balancer"
  }
}

# ─── ALB Target Group ────────────────────────────────────────────────────────

resource "aws_lb_target_group" "jokejolt" {
  name     = "${var.project_name}-tg"
  port     = var.k8s_container_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  stickiness {
    enabled = false
    type    = "app_cookie"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# ─── ALB Listener (HTTP - Redirect to HTTPS) ─────────────────────────────────

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.jokejolt.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    Name = "${var.project_name}-http-listener"
  }
}

# ─── ALB Listener (HTTPS) ────────────────────────────────────────────────────

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.jokejolt.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ssl_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jokejolt.arn
  }

  tags = {
    Name = "${var.project_name}-https-listener"
  }
}

# ─── ALB Listener Rules ──────────────────────────────────────────────────────

resource "aws_lb_listener_rule" "main" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jokejolt.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  condition {
    host_header {
      values = var.domain_names != [] ? var.domain_names : ["jokejolt.example.com"]
    }
  }

  tags = {
    Name = "${var.project_name}-listener-rule"
  }
}

# ─── SSL Certificate Variable ────────────────────────────────────────────────

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate in AWS Certificate Manager"
  type        = string
  default     = ""
}

variable "domain_names" {
  description = "Domain names for the application"
  type        = list(string)
  default     = []
}

# ─── S3 Bucket for ALB Logs ──────────────────────────────────────────────────

resource "aws_s3_bucket" "alb_logs" {
  count = var.environment == "production" ? 1 : 0

  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "${var.project_name}-alb-logs"
    Type = "ALB Access Logs"
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  count = var.environment == "production" ? 1 : 0

  bucket = aws_s3_bucket.alb_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  count = var.environment == "production" ? 1 : 0

  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count = var.environment == "production" ? 1 : 0

  bucket = aws_s3_bucket.alb_logs[0].id
  policy = data.aws_iam_policy_document.alb_logs[0].json

  depends_on = [aws_s3_bucket_public_access_block.alb_logs]
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  count = var.environment == "production" ? 1 : 0

  bucket = aws_s3_bucket.alb_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "alb_logs" {
  count = var.environment == "production" ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::amazon-elb:root"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}/alb-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
  }
}
