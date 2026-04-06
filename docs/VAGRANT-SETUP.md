# Local Kubernetes Setup with Vagrant

This guide shows you how to test your JokeJolt application with ArgoCD on a local 2-node Kubernetes cluster.

## 📋 Prerequisites

1. **Vagrant** - [Download here](https://www.vagrantup.com/downloads)
2. **VirtualBox** - [Download here](https://www.virtualbox.org/wiki/Downloads)
3. **kubectl** (optional, for manual management) - [Install guide](https://kubernetes.io/docs/tasks/tools/)
4. **ArgoCD CLI** (optional) - [Install guide](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

## 🏗️ Architecture

```
┌─────────────────────────────┐
│     Your Host Machine       │
│                             │
│  ┌──────────────────────┐   │
│  │   k8s-master         │   │
│  │   192.168.50.10      │   │
│  │                      │   │
│  │  - k3s Server        │   │
│  │  - ArgoCD            │   │
│  │  - etcd              │   │
│  └──────────────────────┘   │
│           ↔️                 │
│  ┌──────────────────────┐   │
│  │   k8s-worker         │   │
│  │   192.168.50.11      │   │
│  │                      │   │
│  │  - k3s Agent         │   │
│  │  - Workload Pods     │   │
│  └──────────────────────┘   │
└─────────────────────────────┘
```

## 🚀 Quick Start

### 1. Start the Cluster

```bash
./scripts/setup-vagrant.sh up
```

This will:
- Create 2 Ubuntu 22.04 VMs
- Install Docker on both
- Install k3s (lightweight Kubernetes)
- Install ArgoCD on the master
- Configure networking

⏱️ **First boot takes ~5-10 minutes**

### 2. Check Cluster Status

```bash
./scripts/setup-vagrant.sh status
```

### 3. Get ArgoCD Credentials

```bash
./scripts/setup-vagrant.sh argocd
```

You'll get:
- **URL**: https://192.168.50.10:30443
- **Username**: admin
- **Password**: (auto-generated)

### 4. Setup kubectl (Optional)

```bash
./scripts/setup-vagrant.sh kubeconfig
export KUBECONFIG=~/.kube/config.jokejolt
```

### 5. Deploy JokeJolt

```bash
./scripts/setup-vagrant.sh deploy
```

## 📖 Manual Commands

If you prefer manual control:

### Start VMs

```bash
vagrant up
```

### SSH into Master

```bash
vagrant ssh k8s-master
```

### SSH into Worker

```bash
vagrant ssh k8s-worker
```

### Check Cluster Status (from master)

```bash
vagrant ssh k8s-master
kubectl get nodes
kubectl get pods -n argocd
```

### Access ArgoCD

1. Open browser: `https://192.168.50.10:30443`
2. Login with credentials from `/tmp/argocd-password`
3. Accept the self-signed certificate warning

```bash
# Get password
vagrant ssh k8s-master -c "cat /tmp/argocd-password"
```

## 🎯 Deploy JokeJolt with ArgoCD

### Option 1: Using kubectl

```bash
# Setup kubeconfig
./scripts/setup-vagrant.sh kubeconfig
export KUBECONFIG=~/.kube/config.jokejolt

# Apply manifests
kubectl apply -f argocd/application-staging.yaml
```

### Option 2: Using ArgoCD CLI

```bash
# Login to ArgoCD
argocd login 192.168.50.10:30443 --username admin --password <password> --insecure

# Add Git repository
argocd repo add https://github.com/route/JokeJolt.git

# Create application
argocd app create jokejolt-staging \
  --repo https://github.com/route/JokeJolt.git \
  --path k8s/staging \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace jokejolt-staging

# Sync application
argocd app sync jokejolt-staging

# Check status
argocd app get jokejolt-staging
```

### Option 3: Using ArgoCD UI

1. Login to ArgoCD UI
2. Click "+ New App"
3. Fill in:
   - **Application Name**: jokejolt-staging
   - **Project**: default
   - **Repository URL**: Your local repo or GitHub
   - **Path**: k8s/staging
   - **Cluster URL**: https://kubernetes.default.svc
   - **Namespace**: jokejolt-staging
4. Click "Create"
5. Click "Sync"

## 🔍 Testing the Application

### Port Forward to Test

```bash
# Forward the service to your localhost
kubectl port-forward svc/jokejolt -n jokejolt-staging 3000:80

# Or for production
kubectl port-forward svc/jokejolt -n jokejolt-production 3000:80
```

### Test the API

```bash
# Health check
curl http://localhost:3000/health

# Get a joke
curl http://localhost:3000/joke
```

## 🛠️ Troubleshooting

### Cluster Won't Start

```bash
# Check Vagrant status
vagrant status

# Check VirtualBox
VBoxManage list runningvms

# Destroy and recreate
vagrant destroy -f
vagrant up
```

### ArgoCD Not Accessible

```bash
# Check if ArgoCD pods are running
vagrant ssh k8s-master
kubectl get pods -n argocd

# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Restart ArgoCD
kubectl rollout restart deployment/argocd-server -n argocd
```

### Worker Can't Join Cluster

```bash
# Get token from master
vagrant ssh k8s-master -c "cat /var/lib/rancher/k3s/server/node-token"

# On worker, reinstall with correct token
vagrant ssh k8s-worker
sudo K3S_URL=https://192.168.50.10:6443 \
     K3S_TOKEN=<token-from-master> \
     sh -c "$(curl -sfL https://get.k3s.io)"
```

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n jokejolt-staging

# Check logs
kubectl logs -n jokejolt-staging deployment/jokejolt

# Check events
kubectl get events -n jokejolt-staging --sort-by='.lastTimestamp'
```

### Image Pull Issues

```bash
# Create image pull secret
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_TOKEN \
  -n jokejolt-staging
```

## 🔄 Reset Everything

```bash
# Destroy cluster
./scripts/setup-vagrant.sh down

# Or with vagrant
vagrant destroy -f

# Start fresh
vagrant up
```

## 📊 Useful Commands

### kubectl Cheatsheet

```bash
# View all resources
kubectl get all --all-namespaces

# Check cluster info
kubectl cluster-info

# View ArgoCD applications
kubectl get applications -n argocd

# Watch pods
watch kubectl get pods -n jokejolt-staging

# Describe pod (debug)
kubectl describe pod <pod-name> -n jokejolt-staging
```

### ArgoCD Cheatsheet

```bash
# List applications
argocd app list

# Get application details
argocd app get jokejolt-staging

# Sync application
argocd app sync jokejolt-staging

# Watch sync status
argocd app wait jokejolt-staging

# Delete application
argocd app delete jokejolt-staging
```

## 🎓 Next Steps

1. **Deploy to staging**: Apply staging manifests
2. **Deploy to production**: Apply production manifests
3. **Configure CI/CD**: Connect with GitHub Actions
4. **Test auto-sync**: Make changes and watch ArgoCD sync
5. **Experiment**: Try scaling, updates, rollbacks

## 💡 Tips

- **Snapshots**: Take VM snapshots before making changes
- **Resources**: 2GB RAM per VM is minimum, 4GB recommended
- **Networking**: VMs use 192.168.50.x network
- **Persistence**: Data persists across reboots
- **Performance**: First boot is slow, subsequent boots are faster

## 📚 Resources

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [k3s Documentation](https://rancher.com/docs/k3s/latest/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Happy Testing! 🎉**
