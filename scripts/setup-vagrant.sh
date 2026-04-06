#!/bin/bash

# ============================================================================
# JokeJolt Local Kubernetes Setup Helper Script
# ============================================================================
# This script helps you set up and manage the local K8s cluster with ArgoCD
# ============================================================================

set -e

MASTER_IP="192.168.50.10"
WORKER_IP="192.168.50.11"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

show_help() {
    echo "========================================"
    echo "  JokeJolt Kubernetes Setup Helper"
    echo "========================================"
    echo ""
    echo "Usage: ./scripts/setup-vagrant.sh <command>"
    echo ""
    echo "Commands:"
    echo "  up          - Start the Vagrant cluster"
    echo "  down        - Destroy the Vagrant cluster"
    echo "  status      - Check cluster status"
    echo "  argocd      - Get ArgoCD access details"
    echo "  kubeconfig  - Setup kubeconfig on host"
    echo "  deploy      - Deploy JokeJolt to cluster"
    echo "  help        - Show this help message"
    echo ""
    echo "========================================"
}

check_vagrant() {
    if ! command -v vagrant &> /dev/null; then
        print_error "Vagrant is not installed"
        echo "Install from: https://www.vagrantup.com/downloads"
        exit 1
    fi

    if ! command -v VBoxManage &> /dev/null; then
        print_error "VirtualBox is not installed"
        echo "Install from: https://www.virtualbox.org/wiki/Downloads"
        exit 1
    fi

    print_success "Vagrant and VirtualBox found"
}

start_cluster() {
    print_info "Starting JokeJolt Kubernetes cluster..."
    check_vagrant

    echo ""
    print_info "This will create 2 VMs:"
    echo "  - k8s-master (192.168.50.10) - with ArgoCD"
    echo "  - k8s-worker (192.168.50.11)"
    echo ""

    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted"
        exit 0
    fi

    vagrant up

    echo ""
    print_success "Cluster is running!"
    echo ""
    print_info "Next steps:"
    echo "  1. Wait a few minutes for all pods to be ready"
    echo "  2. Run: ./scripts/setup-vagrant.sh argocd"
    echo "  3. Run: ./scripts/setup-vagrant.sh kubeconfig"
    echo ""
}

stop_cluster() {
    print_info "Destroying JokeJolt Kubernetes cluster..."
    check_vagrant

    read -p "This will delete all VMs. Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Aborted"
        exit 0
    fi

    vagrant destroy -f
    print_success "Cluster destroyed"
}

cluster_status() {
    print_info "Checking cluster status..."

    if ! vagrant status | grep -q "running"; then
        print_warning "Cluster is not running. Start it with: ./scripts/setup-vagrant.sh up"
        exit 1
    fi

    print_success "Cluster is running"
    echo ""

    # Check if master is accessible
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no vagrant@$MASTER_IP "echo 2>/dev/null" &> /dev/null; then
        print_success "Master node is accessible"

        # Check k3s
        if ssh vagrant@$MASTER_IP "sudo k3s kubectl cluster-info" &> /dev/null; then
            print_success "Kubernetes API is responding"
        else
            print_warning "Kubernetes API is not responding yet"
        fi
    else
        print_warning "Master node is not accessible"
    fi

    echo ""
    vagrant status
}

get_argocd_info() {
    print_info "Getting ArgoCD access information..."

    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no vagrant@$MASTER_IP "echo 2>/dev/null" &> /dev/null; then
        print_error "Master node is not accessible"
        exit 1
    fi

    echo ""
    echo "========================================"
    echo "  ArgoCD Access Details"
    echo "========================================"
    echo ""

    # Get password
    PASSWORD=$(ssh vagrant@$MASTER_IP "cat /tmp/argocd-password" 2>/dev/null || echo "Error retrieving password")

    echo "URL:      https://$MASTER_IP:30443"
    echo "Username: admin"
    echo "Password: $PASSWORD"
    echo ""
    echo "Note: Your browser may warn about an insecure connection."
    echo "This is normal for self-signed certificates."
    echo ""
    echo "========================================"
    echo ""
    print_info "To login:"
    echo "  argocd login $MASTER_IP:30443 --username admin --password $PASSWORD --insecure"
    echo ""
}

setup_kubeconfig() {
    print_info "Setting up kubeconfig..."

    if ! ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no vagrant@$MASTER_IP "echo 2>/dev/null" &> /dev/null; then
        print_error "Master node is not accessible"
        exit 1
    fi

    # Create .kube directory if it doesn't exist
    mkdir -p ~/.kube

    # Copy kubeconfig from master
    print_info "Copying kubeconfig from master..."
    scp vagrant@$MASTER_IP:~/.kube/config ~/.kube/config.jokejolt

    # Update permissions
    chmod 600 ~/.kube/config.jokejolt

    print_success "Kubeconfig saved to ~/.kube/config.jokejolt"
    echo ""
    print_info "To use it:"
    echo "  export KUBECONFIG=~/.kube/config.jokejolt"
    echo "  kubectl get nodes"
    echo ""
    print_info "Or merge with existing kubeconfig:"
    echo "  KUBECONFIG=~/.kube/config:~/.kube/config.jokejolt kubectl config view --flatten > ~/.kube/config.merged"
    echo "  mv ~/.kube/config.merged ~/.kube/config"
    echo ""
}

deploy_jokejolt() {
    print_info "Deploying JokeJolt to cluster..."

    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        echo "Install from: https://kubernetes.io/docs/tasks/tools/"
        exit 1
    fi

    # Check if kubeconfig is set
    if [ -z "$KUBECONFIG" ]; then
        if [ -f ~/.kube/config.jokejolt ]; then
            export KUBECONFIG=~/.kube/config.jokejolt
        else
            print_error "Kubeconfig not found. Run: ./scripts/setup-vagrant.sh kubeconfig"
            exit 1
        fi
    fi

    echo ""
    print_info "Deploying to staging environment..."

    # Create namespace
    kubectl apply -f k8s/staging/deployment.yaml

    print_success "JokeJolt deployed to staging"
    echo ""
    print_info "Checking deployment status..."
    kubectl get pods -n jokejolt-staging
    echo ""
    print_info "To check deployment:"
    echo "  kubectl get all -n jokejolt-staging"
    echo ""
    print_info "To port-forward and test locally:"
    echo "  kubectl port-forward svc/jokejolt -n jokejolt-staging 3000:80"
    echo "  Then visit: http://localhost:3000"
    echo ""
}

# ─── Main Script ──────────────────────────────────────────────────────────────

case "${1:-help}" in
    up)
        start_cluster
        ;;
    down)
        stop_cluster
        ;;
    status)
        cluster_status
        ;;
    argocd)
        get_argocd_info
        ;;
    kubeconfig)
        setup_kubeconfig
        ;;
    deploy)
        deploy_jokejolt
        ;;
    help|*)
        show_help
        ;;
esac
