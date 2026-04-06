# AWS Deployment Options (Optional - Not Included in Default Pipeline)

This document contains AWS deployment configurations that have been moved to the `backup/` directory. These are optional and can be re-enabled when you're ready to deploy to AWS.

## What Was Removed

The following AWS-specific configurations have been moved to `backup/aws-configs/`:

1. **Full Kubernetes manifests** with AWS-specific annotations
2. **ECR registry integration** in CI/CD pipelines
3. **Manual approval gates** for production deployments
4. **AWS ECS/EKS deployment commands**

## Current Setup

The pipeline now:
- ✅ Pushes images to **GitHub Container Registry (GHCR)** only
- ✅ Uses **ArgoCD** for GitOps-based deployment (no manual approvals)
- ✅ Simplified Kubernetes manifests (cloud-agnostic)

## When Ready for AWS

To re-enable AWS deployment:

1. **Move files back from backup:**
   ```bash
   mv backup/aws-configs/*.yaml k8s/staging/
   mv backup/aws-configs/*.yaml k8s/production/
   ```

2. **Update CI/CD pipelines:**
   - Uncomment ECR stages in `.github/workflows/ci-cd.yml`
   - Uncomment ECR stages in `Jenkinsfile`
   - Add AWS credentials to GitHub secrets

3. **Create AWS resources:**
   - ECR repository
   - EKS cluster or ECS service
   - IAM roles and policies
   - ALB Ingress Controller (for load balancing)

## AWS-Specific Features (In Backup)

- ECR image registry integration
- AWS ALB Ingress annotations
- ECS/EKS deployment commands
- AWS-specific health check endpoints

## Current ArgoCD Workflow

```
GitHub (develop) → ArgoCD detects change → Auto-sync to staging
GitHub (main)    → ArgoCD detects change → Auto-sync to production
```

No manual approvals - fully automated GitOps workflow.
