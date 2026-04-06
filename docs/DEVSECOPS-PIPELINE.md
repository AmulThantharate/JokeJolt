# DevSecOps CI/CD Pipeline Documentation

## 📋 Table of Contents
- [Pipeline Overview](#pipeline-overview)
- [Architecture Diagram](#architecture-diagram)
- [Pipeline Stages](#pipeline-stages)
- [Security Tools](#security-tools)
- [GitHub Actions](#github-actions)
- [Jenkins Pipeline](#jenkins-pipeline)
- [ArgoCD Integration](#argocd-integration)
- [AWS Deployment](#aws-deployment)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Pipeline Overview

This project implements a comprehensive **DevSecOps CI/CD Pipeline** with the following features:

- **GitHub Actions** for automated CI/CD workflows
- **Jenkins** for alternative CI/CD with manual approval gates
- **ArgoCD** for GitOps-based continuous deployment
- **Multiple Security Scanning** stages:
  - SAST (Static Application Security Testing)
  - DAST (Dynamic Application Security Testing)
  - Dependency scanning
  - Container image scanning
  - Infrastructure as Code scanning
  - Nuclei vulnerability scanning
- **Container Registry** integration (GitHub Container Registry + AWS ECR)
- **AWS Deployment** (ECS/EKS ready)
- **Multi-environment** support (Staging & Production)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DEVSECOPS CI/CD PIPELINE                             │
└─────────────────────────────────────────────────────────────────────────────┘

                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  1. DEVELOPER WORKFLOW                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Developer pushes code ──→ GitHub Repository                              │
│   (feature/develop/main)       │                                            │
│                                ├── Pull Request triggers CI                │
│                                └── Push to main/develop triggers full     │
│                                     pipeline + deployment                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  2. CONTINUOUS INTEGRATION (CI)                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐     │
│  │  Code Quality    │    │   Unit Tests     │    │  Lint & Style    │     │
│  │  - ESLint (SAST) │    │  - Jest          │    │  - Prettier      │     │
│  │  - Code Coverage │    │  - Smoke Tests   │    │                  │     │
│  └────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘     │
│           │                       │                        │                │
│           └───────────────────────┼────────────────────────┘                │
│                                   │                                         │
│  ┌────────────────────────────────▼─────────────────────────────────┐     │
│  │               DEPENDENCY SCANNING                                │     │
│  │  - npm audit                                                     │     │
│  │  - Trivy filesystem scan                                         │     │
│  │  - SCA (Software Composition Analysis)                           │     │
│  └───────────────────────────────┬──────────────────────────────────┘     │
│                                  │                                         │
└──────────────────────────────────┼─────────────────────────────────────────┘
                                   │
                                   │ All checks pass
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  3. BUILD & CONTAINER SECURITY                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐                                                       │
│  │  Docker Build    │ ──→ Build multi-stage Docker image                   │
│  └────────┬─────────┘                                                       │
│           │                                                                 │
│           ▼                                                                 │
│  ┌──────────────────────────────────────────────────────────┐              │
│  │         CONTAINER SECURITY SCANNING                      │              │
│  │  - Trivy image scan (CRITICAL, HIGH)                     │              │
│  │  - Nuclei DAST scan (API, Node.js templates)             │              │
│  │  - Hadolint (Dockerfile best practices)                  │              │
│  └────────────────┬─────────────────────────────────────────┘              │
│                   │                                                         │
└───────────────────┼─────────────────────────────────────────────────────────┘
                    │
                    │ All security checks pass
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  4. CONTAINER REGISTRY                                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────┐    ┌──────────────────────────┐              │
│  │   GitHub Container       │    │   AWS Elastic Container  │              │
│  │   Registry (GHCR)       │    │   Registry (ECR)          │              │
│  │                          │    │                           │              │
│  │  ghcr.io/route/         │    │  ACCOUNT.dkr.ecr.         │              │
│  │  joke-jolt:{tag}        │    │  REGION.amazonaws.com/    │              │
│  │                          │    │  joke-jolt:{tag}          │              │
│  └──────────────────────────┘    └──────────────────────────┘              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                    │
                    │ Image pushed
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  5. INFRASTRUCTURE & IaC SCANNING                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────┐              │
│  │  Infrastructure as Code Security                        │              │
│  │  - Trivy config scan (K8s manifests, Dockerfile)        │              │
│  │  - Kubernetes security policies                         │              │
│  │  - Network policy validation                            │              │
│  └────────────────┬────────────────────────────────────────┘              │
│                   │                                                        │
└───────────────────┼────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  6. ARGOCD GITOPS DEPLOYMENT                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐                                                       │
│  │  ArgoCD         │ ──→ Watches for Git changes                          │
│  │                 │ ──→ Syncs K8s manifests to cluster                   │
│  └────────┬────────┘                                                       │
│           │                                                                 │
│           ├──→ Staging (develop branch)                                    │
│           │    k8s/staging/deployment.yaml                                 │
│           │    Auto-sync enabled                                           │
│           │                                                                 │
│           └──→ Production (main branch)                                    │
│                k8s/production/deployment.yaml                              │
│                Manual approval required                                    │
└───────────────────┼─────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  7. AWS DEPLOYMENT                                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────┐              │
│  │  Staging Environment                                     │              │
│  │  - Namespace: jokejolt-staging                           │              │
│  │  - Replicas: 2                                           │              │
│  │  - Auto-scaling: 2-10 pods                               │              │
│  │  - URL: http://staging-jokejolt.example.com              │              │
│  └──────────────────────────────────────────────────────────┘              │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────┐              │
│  │  Production Environment                                   │              │
│  │  - Namespace: jokejolt-production                        │              │
│  │  - Replicas: 3                                           │              │
│  │  - Auto-scaling: 3-20 pods                               │              │
│  │  - URL: http://production-jokejolt.example.com           │              │
│  └──────────────────────────────────────────────────────────┘              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  8. CONTINUOUS MONITORING                                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  - Health checks: /health endpoint every 10s                                │
│  - Metrics: CPU, Memory, Request latency                                   │
│  - Alerts: Failed deployments, High error rates                            │
│  - Logging: Application logs + Security scan results                       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Simplified Flow:
```
Code → CI (Tests + SAST + Deps) → Build → Container Scan → Nuclei DAST → 
Registry → IaC Scan → ArgoCD → Staging → Manual Approval → Production
```

---

## Pipeline Stages

### Stage 1: Code Quality & SAST
- **Tool**: ESLint
- **Purpose**: Static code analysis for security vulnerabilities
- **Output**: SARIF format for GitHub Security tab
- **Threshold**: Must pass before proceeding

### Stage 2: Unit Testing
- **Tool**: Jest
- **Coverage Requirement**: Minimum 80%
- **Tests**: Functional tests, integration tests
- **Smoke Tests**: Post-build validation

### Stage 3: Dependency Scanning
- **Tools**: npm audit, Trivy
- **Severity**: Critical, High
- **Action**: Fails on critical vulnerabilities
- **Report**: JSON artifacts archived

### Stage 4: Container Build & Security
- **Build**: Multi-stage Docker build
- **Scan**: Trivy container scan
- **Blocker**: Critical CVEs fail the pipeline
- **Registry**: Push to GHCR on success

### Stage 5: Nuclei Security Scanning
- **Tool**: Nuclei
- **Target**: Running container
- **Templates**: API, Node.js, JWT, CORS
- **Severity**: Critical, High, Medium
- **Rate Limit**: 50 requests/sec
- **Output**: JSON and text reports

### Stage 6: Infrastructure as Code Scanning
- **Tool**: Trivy config scan
- **Targets**: Kubernetes manifests, Dockerfile
- **Rules**: CIS benchmarks, security best practices

### Stage 7: Deploy to Staging
- **Trigger**: Push to `develop` branch
- **Auto-sync**: ArgoCD watches for changes
- **Environment**: AWS EKS/ECS staging namespace
- **Validation**: Health check + smoke tests

### Stage 8: Deploy to Production
- **Trigger**: Push to `main` branch
- **Approval**: Manual approval required in Jenkins
- **ArgoCD**: Syncs production manifests
- **Environment**: AWS EKS/ECS production namespace

---

## Security Tools

### 1. **ESLint** (SAST)
- Static analysis for JavaScript
- Finds security anti-patterns
- Integrated into CI pipeline

### 2. **npm audit**
- Dependency vulnerability scanning
- Blocks on critical vulnerabilities
- Generates audit reports

### 3. **Trivy**
- **Filesystem Scan**: Project dependencies and code
- **Container Scan**: Docker image vulnerabilities
- **IaC Scan**: Kubernetes manifests and Dockerfile
- **Severity Filter**: CRITICAL, HIGH only

### 4. **Nuclei**
- Dynamic Application Security Testing (DAST)
- API security scanning
- Template-based vulnerability detection
- Custom templates for application-specific checks
- Rate-limited scanning to avoid DoS

### 5. **Hadolint**
- Dockerfile best practices
- Container security guidelines
- Linting for Docker configurations

### 6. **Kubernetes Security**
- Network policies (restrict traffic)
- Pod disruption budgets (high availability)
- RBAC (role-based access control)
- Resource limits (prevent DoS)

---

## GitHub Actions

### Workflow File: `.github/workflows/ci-cd.yml`

**Triggers**:
- Push to `main` or `develop` branches
- Pull requests to `main`

**Jobs**:
1. `code-quality`: ESLint + Tests
2. `dependency-scan`: npm audit + Trivy
3. `container-security`: Build + Trivy container scan
4. `iac-scan`: Trivy config scan
5. `nuclei-scan`: Nuclei DAST on running container
6. `deploy-staging`: Auto-deploy develop to staging
7. `deploy-production`: Auto-deploy main to production

**Environment Variables**:
- `REGISTRY`: ghcr.io
- `IMAGE_NAME`: Repository name
- `AWS_REGION`: AWS region (from secrets)
- `ECR_REPOSITORY`: ECR repo name (from secrets)

**Required Secrets**:
- `GITHUB_TOKEN`: Automatic (provided by GitHub)
- `AWS_ACCESS_KEY_ID`: AWS credentials
- `AWS_SECRET_ACCESS_KEY`: AWS credentials
- `AWS_REGION`: AWS region
- `ECR_REPOSITORY`: ECR repository name

---

## Jenkins Pipeline

### Jenkinsfile

**Parameters**:
- `DEPLOY_ENV`: none, staging, or production
- `RUN_SECURITY_SCAN`: Boolean (default: true)
- `PUSH_TO_GHCR`: Boolean (default: true)

**Stages**:
1. Checkout & Setup
2. Install Dependencies
3. Code Quality & Linting
4. Unit Tests
5. Dependency Scanning
6. Trivy Filesystem Scan
7. Build Docker Image
8. Container Security Scan
9. Nuclei Security Scan
10. Infrastructure as Code Scan
11. Push to GitHub Container Registry
12. Push to Amazon ECR
13. Deploy to Staging
14. Deploy to Production (requires approval)

**Required Jenkins Credentials**:
- `GITHUB_TOKEN`: GitHub personal access token
- `GITHUB_USERNAME`: Your GitHub username
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

---

## ArgoCD Integration

### Application Structure

```
argocd/
├── project.yaml                  # AppProject definition
├── application-staging.yaml      # Staging application
└── application-production.yaml   # Production application

k8s/
├── staging/
│   └── deployment.yaml          # Staging K8s manifests
└── production/
    └── deployment.yaml          # Production K8s manifests
```

### Setup ArgoCD

1. **Install ArgoCD**:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

2. **Add GitHub Repository**:
```bash
argocd repo add https://github.com/route/JokeJolt.git
```

3. **Apply ArgoCD Manifests**:
```bash
kubectl apply -f argocd/project.yaml
kubectl apply -f argocd/application-staging.yaml
kubectl apply -f argocd/application-production.yaml
```

4. **Access ArgoCD UI**:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### ArgoCD Features
- **Auto-sync**: Automatically deploys changes from Git
- **Self-heal**: Reverts manual changes to match Git
- **Prune**: Removes resources deleted from Git
- **Health Checks**: Monitors deployment status

---

## AWS Deployment

### Prerequisites

1. **AWS CLI** configured
2. **EKS Cluster** or **ECS Cluster** created
3. **ECR Repository** created
4. **IAM User** with ECR/EKS permissions
5. **Kubernetes context** configured

### Deploy to AWS EKS

1. **Create ECR Repository**:
```bash
aws ecr create-repository --repository-name joke-jolt
```

2. **Configure kubectl**:
```bash
aws eks update-kubeconfig --region us-east-1 --name your-cluster-name
```

3. **Create Namespaces**:
```bash
kubectl apply -f k8s/staging/deployment.yaml  # Creates namespace
kubectl apply -f k8s/production/deployment.yaml  # Creates namespace
```

4. **Create Image Pull Secret**:
```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  -n jokejolt-staging

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  -n jokejolt-production
```

5. **Deploy with ArgoCD** or manually:
```bash
kubectl apply -f k8s/staging/deployment.yaml
kubectl apply -f k8s/production/deployment.yaml
```

### Deploy to AWS ECS

For ECS, update the deployment commands in CI/CD:

```bash
# Update ECS service
aws ecs update-service \
  --cluster staging \
  --service jokejolt \
  --force-new-deployment \
  --region us-east-1
```

---

## Configuration

### GitHub Secrets Setup

| Secret Name | Description | Example |
|------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | AWS region | `us-east-1` |
| `ECR_REPOSITORY` | ECR repo name | `joke-jolt` |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Node environment | `production` |
| `PORT` | Application port | `3000` |
| `REGISTRY` | Container registry | `ghcr.io` |
| `IMAGE_TAG` | Docker image tag | `{branch}-{sha}` |

---

## Troubleshooting

### Common Issues

#### 1. **Docker Build Fails**
```
Error: failed to solve with frontend dockerfile
```
**Solution**: Ensure Dockerfile syntax is correct
```bash
hadolint Dockerfile
```

#### 2. **Nuclei Scan Timeout**
```
Error: context deadline exceeded
```
**Solution**: Increase timeout or reduce rate limit in `.nucleiconfig`

#### 3. **Trivy Scan Fails**
```
Error: failed to parse the config file
```
**Solution**: Validate Trivy configuration syntax

#### 4. **ECR Authentication Fails**
```
Error: no basic auth credentials
```
**Solution**: Re-authenticate with ECR
```bash
aws ecr get-login-password --region REGION | \
  docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.REGION.amazonaws.com
```

#### 5. **ArgoCD Sync Fails**
```
Error: comparison is more than configured limit
```
**Solution**: Increase resource exclusions in ArgoCD config

#### 6. **Kubernetes ImagePullBackOff**
```
Error: Failed to pull image
```
**Solution**: Verify image pull secret
```bash
kubectl get secret ghcr-secret -n jokejolt-staging
kubectl delete secret ghcr-secret -n jokejolt-staging
# Recreate with correct credentials
```

### Pipeline Performance Optimization

1. **Enable Caching**:
   - GitHub Actions: Uses `actions/cache`
   - Jenkins: Use workspace caching

2. **Parallel Jobs**:
   - Independent stages run in parallel
   - Security scans run after build

3. **Conditional Execution**:
   - Skip security scans on PRs if not needed
   - Only deploy on specific branches

4. **Artifact Retention**:
   - Keep only last 10 builds
   - Compress large artifacts

### Security Best Practices

1. **Rotate Credentials**: Regular rotation of AWS keys and tokens
2. **Use OIDC**: Use OpenID Connect for AWS authentication
3. **Scope Permissions**: Minimal permissions for CI/CD roles
4. **Scan Before Deploy**: All security scans must pass
5. **Manual Approval**: Production requires manual approval
6. **Audit Logs**: Enable audit logging for all deployments

---

## Pipeline Status Badges

Add these to your README.md:

```markdown
![CI/CD](https://github.com/route/JokeJolt/actions/workflows/ci-cd.yml/badge.svg)
![Security Scan](https://img.shields.io/badge/security-passing-green)
![License](https://img.shields.io/badge/license-MIT-blue)
```

---

## Next Steps

1. **Monitoring**: Add Prometheus + Grafana for metrics
2. **Logging**: Implement ELK stack or CloudWatch Logs
3. **Alerting**: Configure Slack/Email alerts
4. **Backup**: Implement backup strategy for production
5. **Disaster Recovery**: Plan for multi-region deployment
6. **Compliance**: Add SOC2, HIPAA compliance checks

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Nuclei Templates](https://nuclei.projectdiscovery.io/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
