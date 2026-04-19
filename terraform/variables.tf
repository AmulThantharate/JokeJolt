# ─── General Configuration ───────────────────────────────────────────────────

variable "region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (staging/production)"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
  default     = "jokejolt"
}

# ─── VPC Configuration ───────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ─── EKS Cluster Configuration ───────────────────────────────────────────────

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_public_access" {
  description = "Whether the cluster endpoint is publicly accessible"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Whether the cluster endpoint is privately accessible"
  type        = bool
  default     = true
}

# ─── Node Group Configuration ────────────────────────────────────────────────

variable "node_group_instance_types" {
  description = "EC2 instance types for node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "node_group_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 10
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 50
}

# ─── ECR Configuration ───────────────────────────────────────────────────────

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "joke-jolt"
}

variable "ecr_image_tag_mutability" {
  description = "Whether image tags are mutable"
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.ecr_image_tag_mutability)
    error_message = "Tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "ecr_scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

# ─── Kubernetes Deployment Configuration ─────────────────────────────────────

variable "k8s_namespace" {
  description = "Kubernetes namespace for application"
  type        = string
  default     = "jokejolt-production"
}

variable "k8s_replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 3
}

variable "k8s_container_port" {
  description = "Container port for the application"
  type        = number
  default     = 3000
}

variable "k8s_image_tag" {
  description = "Docker image tag for deployment"
  type        = string
  default     = "main-latest"
}

# ─── Resource Configuration ──────────────────────────────────────────────────

variable "container_cpu_requests" {
  description = "CPU requests for containers"
  type        = string
  default     = "200m"
}

variable "container_memory_requests" {
  description = "Memory requests for containers"
  type        = string
  default     = "256Mi"
}

variable "container_cpu_limits" {
  description = "CPU limits for containers"
  type        = string
  default     = "1000m"
}

variable "container_memory_limits" {
  description = "Memory limits for containers"
  type        = string
  default     = "1Gi"
}

# ─── Auto-scaling Configuration ──────────────────────────────────────────────

variable "hpa_min_replicas" {
  description = "Minimum replicas for HPA"
  type        = number
  default     = 3
}

variable "hpa_max_replicas" {
  description = "Maximum replicas for HPA"
  type        = number
  default     = 20
}

variable "hpa_cpu_target_utilization" {
  description = "Target CPU utilization percentage for HPA"
  type        = number
  default     = 60
}

variable "hpa_memory_target_utilization" {
  description = "Target memory utilization percentage for HPA"
  type        = number
  default     = 75
}

# ─── Monitoring & Logging ────────────────────────────────────────────────────

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs for EKS"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_container_insights" {
  description = "Enable Container Insights for monitoring"
  type        = bool
  default     = true
}

# ─── Security Configuration ──────────────────────────────────────────────────

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_waf" {
  description = "Enable AWS WAF for web application firewall"
  type        = bool
  default     = false
}

# ─── Tags ─────────────────────────────────────────────────────────────────────

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
