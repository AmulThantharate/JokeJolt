# ─── Infrastructure Outputs ──────────────────────────────────────────────────

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "node_security_group_id" {
  description = "Security group ID attached to the node group"
  value       = aws_security_group.node.id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.jokejolt.dns_name
}

output "alb_arn" {
  description = "The ARN of the load balancer"
  value       = aws_lb.jokejolt.arn
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.jokejolt.repository_url
}

# ─── Kubernetes Outputs ──────────────────────────────────────────────────────

output "k8s_service_name" {
  description = "Kubernetes service name"
  value       = kubernetes_service.jokejolt.metadata[0].name
}

output "k8s_namespace" {
  description = "Kubernetes namespace"
  value       = kubernetes_namespace.production.metadata[0].name
}

output "k8s_deployment_name" {
  description = "Kubernetes deployment name"
  value       = kubernetes_deployment.jokejolt.metadata[0].name
}

output "k8s_service_account" {
  description = "Kubernetes service account name"
  value       = kubernetes_service_account.app.metadata[0].name
}

# ─── IAM Outputs ──────────────────────────────────────────────────────────────

output "application_role_arn" {
  description = "ARN of the application IAM role"
  value       = aws_iam_role.application.arn
}

output "node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.eks_node.arn
}

# ─── Connection Information ──────────────────────────────────────────────────

output "configure_kubectl" {
  description = "Command to configure kubectl for this cluster"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "test_application" {
  description = "Command to test the application"
  value       = "kubectl port-forward svc/jokejolt -n ${kubernetes_namespace.production.metadata[0].name} 8080:80"
}

# ─── Monitoring Outputs ──────────────────────────────────────────────────────

output "cloudwatch_log_group" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.eks.name
}

output "cloudwatch_alarms" {
  description = "List of CloudWatch alarm names"
  value = [
    aws_cloudwatch_metric_alarm.high_cpu.alarm_name,
    aws_cloudwatch_metric_alarm.high_memory.alarm_name,
    aws_cloudwatch_metric_alarm.node_count.alarm_name,
    aws_cloudwatch_metric_alarm.pod_count.alarm_name,
  ]
}
