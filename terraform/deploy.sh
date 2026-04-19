#!/bin/bash
#
# Deployment Script for JokeJolt
# Automates the Terraform workflow for production deployment
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TFVARS_FILE="${TERRAFORM_DIR}/terraform.tfvars"
IMAGE_NAME="joke-jolt"
REGISTRY_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=${AWS_REGION:-us-east-1}

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi

    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed"
        exit 1
    fi

    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials are not configured"
        exit 1
    fi

    # Check terraform.tfvars exists
    if [ ! -f "$TFVARS_FILE" ]; then
        log_error "terraform.tfvars not found. Copy terraform.tfvars.example and configure."
        exit 1
    fi

    log_info "All prerequisites met ✓"
}

build_and_push_image() {
    log_info "Building and pushing Docker image..."

    cd "$TERRAFORM_DIR/../"

    # Get image tag from argument or use latest
    IMAGE_TAG="${1:-latest}"

    # Build image
    log_info "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

    # Tag for ECR
    ECR_URL="${REGISTRY_ID}.dkr.ecr.${REGION}.amazonaws.com"
    docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

    # Login to ECR
    aws ecr get-login-password --region "$REGION" | \
        docker login --username AWS --password-stdin "${ECR_URL}"

    # Push to ECR
    docker push "${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

    log_info "Image pushed to ECR: ${ECR_URL}/${IMAGE_NAME}:${IMAGE_TAG}"

    cd "$TERRAFORM_DIR"
}

init_terraform() {
    log_info "Initializing Terraform..."

    cd "$TERRAFORM_DIR"

    terraform init \
      -backend-config="bucket=jokejolt-terraform-state-${REGISTRY_ID}" \
      -backend-config="key=jokejolt/production/terraform.tfstate" \
      -backend-config="region=${REGION}"

    log_info "Terraform initialized ✓"
}

plan_terraform() {
    log_info "Planning Terraform deployment..."

    cd "$TERRAFORM_DIR"

    terraform plan \
      -var-file="$TFVARS_FILE" \
      -out=tfplan

    log_info "Terraform plan created ✓"
}

apply_terraform() {
    log_info "Applying Terraform configuration..."

    cd "$TERRAFORM_DIR"

    terraform apply -auto-approve tfplan

    log_info "Terraform apply completed ✓"
}

deploy_kubernetes() {
    log_info "Deploying to Kubernetes..."

    cd "$TERRAFORM_DIR"

    # Get cluster credentials
    aws eks --region "$REGION" update-kubeconfig --name "jokejolt-eks"

    # Wait for deployment to be ready
    kubectl rollout status deployment/jokejolt -n jokejolt-production --timeout=300s

    log_info "Kubernetes deployment complete ✓"
}

show_outputs() {
    log_info "Deployment outputs:"
    echo ""
    terraform output -raw alb_dns_name 2>/dev/null || echo "ALB DNS not available"
    echo ""
    terraform output -raw cluster_endpoint 2>/dev/null || echo "Cluster endpoint not available"
    echo ""
}

verify_deployment() {
    log_info "Verifying deployment..."

    cd "$TERRAFORM_DIR"

    # Get kubernetes service
    ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "")

    if [ -n "$ALB_DNS" ]; then
        log_info "Testing application health..."
        if curl -sf "http://${ALB_DNS}/health" > /dev/null 2>&1; then
            log_info "Application is healthy ✓"
        else
            log_warn "Application health check failed - it may still be starting"
        fi
    fi

    # Check pod status
    POD_COUNT=$(kubectl get pods -n jokejolt-production -l app=jokejolt --no-headers 2>/dev/null | wc -l || echo "0")
    log_info "Running pods: ${POD_COUNT}"
}

# Main workflow
main() {
    local action="${1:-deploy}"

    case "$action" in
        deploy)
            log_info "Starting JokeJolt production deployment..."
            echo ""

            check_prerequisites
            # Uncomment to build and push during deploy
            # build_and_push_image "${2:-latest}"
            init_terraform
            plan_terraform
            apply_terraform
            deploy_kubernetes
            show_outputs
            verify_deployment

            echo ""
            log_info "Deployment completed successfully! 🚀"
            ;;

        build)
            build_and_push_image "${2:-latest}"
            ;;

        init)
            check_prerequisites
            init_terraform
            ;;

        plan)
            check_prerequisites
            init_terraform
            plan_terraform
            ;;

        apply)
            check_prerequisites
            init_terraform
            apply_terraform
            deploy_kubernetes
            show_outputs
            ;;

        verify)
            verify_deployment
            ;;

        destroy)
            log_warn "This will destroy all infrastructure!"
            read -p "Type 'destroy' to confirm: " confirm
            if [ "$confirm" == "destroy" ]; then
                cd "$TERRAFORM_DIR"
                terraform destroy -var-file="$TFVARS_FILE"
                log_info "Infrastructure destroyed"
            fi
            ;;

        *)
            echo "Usage: $0 {deploy|build|init|plan|apply|verify|destroy} [image_tag]"
            echo ""
            echo "Commands:"
            echo "  deploy  - Full deployment (init, plan, apply, deploy)"
            echo "  build   - Build and push Docker image"
            echo "  init    - Initialize Terraform"
            echo "  plan    - Show Terraform plan"
            echo "  apply   - Apply Terraform configuration"
            echo "  verify  - Verify deployment health"
            echo "  destroy - Destroy all infrastructure"
            exit 1
            ;;
    esac
}

main "$@"
