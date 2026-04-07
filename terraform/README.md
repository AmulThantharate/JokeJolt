# JokeJolt Production Terraform

This directory contains Terraform configuration for deploying JokeJolt to AWS with production-grade infrastructure.

## Architecture

The Terraform configuration provisions:

- **Networking**: VPC with public/private subnets across 3 AZs
- **Compute**: EKS cluster with managed node groups
- **Registry**: ECR repository with image scanning and lifecycle policies
- **Load Balancing**: Application Load Balancer with SSL termination
- **Kubernetes**: Full K8s manifests (Deployment, Service, HPA, PDB, NetworkPolicy)
- **Security**: IAM roles with least privilege, security groups, network policies
- **Monitoring**: CloudWatch Logs, Container Insights, custom alarms
- **Auto-scaling**: Horizontal Pod Autoscaler based on CPU/memory

## Prerequisites

1. **Terraform** >= 1.6.0 installed
2. **AWS CLI** configured with appropriate credentials
3. **kubectl** for interacting with the cluster
4. **Docker** for building and pushing images

## Quick Start

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Review Plan

Create a `terraform.tfvars` file with your custom values:

```hcl
region          = "us-east-1"
environment     = "production"
project_name    = "jokejolt"
k8s_image_tag   = "main-latest"
ssl_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxx-xxx-xxx"
domain_names    = ["jokejolt.example.com"]
```

Then review the plan:

```bash
terraform plan -var-file="terraform.tfvars"
```

### 3. Apply Configuration

```bash
terraform apply -var-file="terraform.tfvars"
```

### 4. Configure kubectl

```bash
aws eks --region us-east-1 update-kubeconfig --name jokejolt-eks
```

### 5. Deploy Application

The Kubernetes resources are automatically created by Terraform. To update the deployment with a new image:

```bash
kubectl set image deployment/jokejolt jokejolt=YOUR_ECR_URL:jokejolt:TAG -n jokejolt-production
```

## Remote State (S3 Backend)

For production, configure remote state storage:

1. Create an S3 bucket for Terraform state:

```bash
aws s3api create-bucket --bucket your-terraform-state-bucket --region us-east-1
```

2. Create a DynamoDB table for state locking:

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockId,AttributeType=S \
  --key-schema AttributeName=LockId,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

3. Uncomment the `backend "s3"` block in `versions.tf` and update:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "jokejolt/production/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "terraform-state-lock"
  encrypt        = true
}
```

## Configuration Variables

### Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `region` | AWS region | `us-east-1` |
| `environment` | Environment name | `production` |
| `ssl_certificate_arn` | ACM certificate ARN for HTTPS | _(required for HTTPS)_ |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `node_group_instance_types` | EC2 instance types | `["t3.medium"]` |
| `node_group_desired_size` | Number of worker nodes | `3` |
| `k8s_image_tag` | Docker image tag | `main-latest` |
| `hpa_min_replicas` | Minimum pod replicas | `3` |
| `hpa_max_replicas` | Maximum pod replicas | `20` |

See `variables.tf` for the complete list.

## Infrastructure Resources

### Networking
- VPC with 3 public and 3 private subnets
- NAT Gateways for private subnet internet access
- Internet Gateway for public subnet access
- Route tables and associations

### EKS Cluster
- Managed node group with auto-scaling
- CloudWatch logging enabled
- IAM roles with least privilege
- OIDC provider for IRSA

### Kubernetes Resources
- Namespace: `jokejolt-production`
- Deployment with resource requests/limits
- Service (LoadBalancer type)
- HorizontalPodAutoscaler (3-20 replicas)
- PodDisruptionBudget (min 2 available)
- NetworkPolicy (restrict traffic)
- ServiceAccount with IAM role binding

### Monitoring
- CloudWatch Log Groups
- Container Insights
- Custom alarms for CPU, memory, node count, pod count
- ALB access logs to S3

## Security Features

- **Least Privilege IAM**: Roles scoped to minimum required permissions
- **Network Isolation**: Private subnets for worker nodes
- **Security Groups**: Restricted ingress/egress rules
- **Image Scanning**: ECR automatic scanning on push
- **Encryption**: ECR images encrypted with AES256
- **Network Policies**: Kubernetes network policies restrict traffic
- **Pod Security**: Service accounts with IRSA

## Cost Optimization

- **Auto-scaling**: HPA scales pods based on demand
- **Spot Instances**: Can be enabled for non-critical workloads
- **Lifecycle Policies**: ECR lifecycle policies remove old images
- **Log Retention**: CloudWatch logs retained for 30 days

## Updating the Application

### Via Terraform

Update the image tag in `terraform.tfvars`:

```hcl
k8s_image_tag = "main-abc1234"
```

Then apply:

```bash
terraform apply -var-file="terraform.tfvars"
```

### Via kubectl

```bash
kubectl set image deployment/jokejolt \
  jokejolt=YOUR_ECR_URL:jokejolt:TAG \
  -n jokejolt-production
```

## Monitoring & Troubleshooting

### Check Cluster Status

```bash
kubectl get nodes
kubectl get pods -n jokejolt-production
```

### View Logs

```bash
# Application logs
kubectl logs -f deployment/jokejolt -n jokejolt-production

# CloudWatch logs
aws logs tail /aws/eks/jokejolt-eks/cluster --follow
```

### CloudWatch Alarms

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefixes jokejolt
```

### Access Application

```bash
# Get load balancer DNS
terraform output -raw alb_dns_name

# Port forward for local testing
kubectl port-forward svc/jokejolt -n jokejolt-production 8080:80
```

## Teardown

To destroy all resources:

```bash
terraform destroy -var-file="terraform.tfvars"
```

## Module Structure

```
terraform/
├── versions.tf          # Provider versions and backend
├── provider.tf          # Provider configurations
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── networking.tf        # VPC, subnets, gateways
├── ecr.tf               # ECR repository
├── eks.tf               # EKS cluster and node group
├── iam.tf               # IAM roles and policies
├── kubernetes.tf        # K8s resources (deployment, service, etc.)
├── load-balancer.tf     # ALB and target groups
├── monitoring.tf        # CloudWatch alarms and logging
└── README.md            # This file
```

## Best Practices

1. **Use Remote State**: Always use S3 backend for production
2. **Enable Versioning**: Keep Terraform state in version control (not the actual tfstate files)
3. **Lock State**: Use DynamoDB for state locking
4. **Review Changes**: Always run `terraform plan` before applying
5. **Tag Resources**: Use consistent tagging for cost tracking
6. **Rotate Credentials**: Regularly rotate AWS credentials
7. **Test in Staging**: Validate changes in staging first

## Troubleshooting

### EKS Cluster Not Ready
```bash
aws eks wait cluster-active --name jokejolt-eks
```

### ImagePullBackOff Error
- Verify ECR image exists
- Check image pull secret configuration
- Ensure IAM permissions are correct

### Terraform Apply Fails
- Check AWS credentials
- Verify quotas (VPCs, EKS clusters, etc.)
- Review CloudWatch/CloudFormation permissions

## Notes

- SSL certificate must be in the same region as the ALB
- Domain names must be configured in Route53 or external DNS
- For staging, change `environment` variable to "staging"
