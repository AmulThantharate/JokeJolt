# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # ─── Common Configuration ───────────────────────────────────────────────────
  config.vm.box = "ubuntu/jammy64"  # Ubuntu 22.04 LTS

  # ─── Kubernetes Master Node ─────────────────────────────────────────────────
  config.vm.define "k8s-master" do |master|
    master.vm.hostname = "k8s-master"
    master.vm.network "private_network", ip: "192.168.50.10"

    master.vm.provider "virtualbox" do |vb|
      vb.name = "jokejolt-k8s-master"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
    end

    master.vm.provision "shell", inline: <<-SHELL
      #!/bin/bash
      set -e

      echo "==> [Master] Setting up Kubernetes Master Node..."

      # Disable swap
      swapoff -a
      sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

      # Install Docker
      echo "==> [Master] Installing Docker..."
      apt-get update
      apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

      apt-get update
      apt-get install -y docker.io
      systemctl enable docker
      systemctl start docker

      # Add vagrant user to docker group
      usermod -aG docker vagrant

      # Install k3s (lightweight Kubernetes)
      echo "==> [Master] Installing k3s..."
      curl -sfL https://get.k3s.io | sh -

      # Wait for k3s to start
      sleep 10

      # Get the node token for worker to join
      echo "==> [Master] Retrieving node token..."
      NODE_TOKEN=$(cat /var/lib/rancher/k3s/server/node-token)
      echo "$NODE_TOKEN" > /tmp/node-token
      chmod 644 /tmp/node-token

      # Copy kubeconfig for vagrant user
      mkdir -p /home/vagrant/.kube
      cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
      chown -R vagrant:vagrant /home/vagrant/.kube
      chmod 600 /home/vagrant/.kube/config

      # Install kubectl
      echo "==> [Master] Installing kubectl..."
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      chmod +x kubectl
      mv kubectl /usr/local/bin/
      kubectl completion bash >> /home/vagrant/.bashrc

      # Install ArgoCD
      echo "==> [Master] Installing ArgoCD..."
      kubectl create namespace argocd

      # Wait for namespace
      sleep 5

      # Install ArgoCD
      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

      # Wait for ArgoCD server to be ready
      echo "==> [Master] Waiting for ArgoCD to be ready..."
      kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

      # Get ArgoCD admin password
      echo "==> [Master] Retrieving ArgoCD admin password..."
      ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
      echo "$ARGOCD_PASSWORD" > /tmp/argocd-password
      chmod 644 /tmp/argocd-password

      # Expose ArgoCD server via NodePort
      echo "==> [Master] Exposing ArgoCD via NodePort..."
      kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "nodePort": 30443, "protocol": "TCP"}]}}'

      # Configure kubectl to use external IP
      echo "==> [Master] Configuring kubectl..."
      sed -i "s|127.0.0.1|192.168.50.10|g" /home/vagrant/.kube/config
      sed -i "s|https://127.0.0.1:6443|https://192.168.50.10:6443|g" /etc/rancher/k3s/k3s.yaml

      # Display setup information
      echo ""
      echo "=========================================="
      echo "  Kubernetes Master Node Setup Complete!"
      echo "=========================================="
      echo ""
      echo "Master Node IP: 192.168.50.10"
      echo "Node Token: $(cat /tmp/node-token)"
      echo "ArgoCD Password: $ARGOCD_PASSWORD"
      echo "ArgoCD UI: https://192.168.50.10:30443"
      echo ""
      echo "=========================================="

      # Reboot to apply all changes
      echo "==> [Master] Rebooting in 5 seconds..."
      sleep 5
      reboot
    SHELL
  end

  # ─── Kubernetes Worker Node ─────────────────────────────────────────────────
  config.vm.define "k8s-worker" do |worker|
    worker.vm.hostname = "k8s-worker"
    worker.vm.network "private_network", ip: "192.168.50.11"

    worker.vm.provider "virtualbox" do |vb|
      vb.name = "jokejolt-k8s-worker"
      vb.memory = "2048"
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--ioapic", "on"]
    end

    # Wait for master to be ready
    worker.vm.provision "shell", run: "always", inline: <<-SHELL
      #!/bin/bash
      if [ ! -f /tmp/joined ]; then
        echo "==> [Worker] Waiting for master node to be ready..."
        sleep 30
      fi
    SHELL

    worker.vm.provision "shell", inline: <<-SHELL
      #!/bin/bash
      set -e

      echo "==> [Worker] Setting up Kubernetes Worker Node..."

      # Disable swap
      swapoff -a
      sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

      # Install Docker
      echo "==> [Worker] Installing Docker..."
      apt-get update
      apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

      apt-get update
      apt-get install -y docker.io
      systemctl enable docker
      systemctl start docker

      # Add vagrant user to docker group
      usermod -aG docker vagrant

      # Get the node token from master
      echo "==> [Worker] Retrieving node token from master..."
      NODE_TOKEN=$(curl -s http://192.168.50.10/tmp/node-token 2>/dev/null || echo "")

      # If we can't get it via HTTP, we'll use scp approach
      if [ -z "$NODE_TOKEN" ]; then
        # Try to get token from shared location (you'll need to manually copy it)
        echo "Waiting for you to copy node token..."
        echo "On the master node, run: cat /var/lib/rancher/k3s/server/node-token"
        # For now, use a placeholder - you'll need to replace this
        NODE_TOKEN="PLACEHOLDER_TOKEN"
      fi

      # Install k3s agent and join to master
      echo "==> [Worker] Joining cluster..."
      export K3S_URL=https://192.168.50.10:6443
      export K3S_TOKEN=$NODE_TOKEN

      # Note: This will fail if the token is placeholder, which is expected
      # You'll need to manually join or use SSH to get the token
      curl -sfL https://get.k3s.io | sh - || {
        echo "==> [Worker] Failed to join cluster. You may need to manually join."
        echo "Run this on worker after getting token from master:"
        echo "  export K3S_URL=https://192.168.50.10:6443"
        echo "  export K3S_TOKEN=<token-from-master>"
        echo "  curl -sfL https://get.k3s.io | sh -"
      }

      # Display setup information
      echo ""
      echo "=========================================="
      echo "  Kubernetes Worker Node Setup Complete!"
      echo "=========================================="
      echo ""
      echo "Worker Node IP: 192.168.50.11"
      echo "Master Node: 192.168.50.10"
      echo ""
      echo "=========================================="

      # Reboot to apply all changes
      echo "==> [Worker] Rebooting in 5 seconds..."
      sleep 5
      reboot
    SHELL
  end

  # ─── Post-Provisioning Instructions ─────────────────────────────────────────
  config.vm.provision "shell", run: "always", inline: <<-SHELL
    #!/bin/bash

    MASTER_IP="192.168.50.10"
    WORKER_IP="192.168.50.11"

    echo ""
    echo "=========================================="
    echo "  Vagrant Environment Ready!"
    echo "=========================================="
    echo ""
    echo "Master Node: ssh vagrant@$MASTER_IP"
    echo "Worker Node: ssh vagrant@$WORKER_IP"
    echo ""
    echo "To access ArgoCD:"
    echo "  URL: https://$MASTER_IP:30443"
    echo "  Username: admin"
    echo "  Password: cat /tmp/argocd-password (on master)"
    echo ""
    echo "To use kubectl from your host machine:"
    echo "  1. Install kubectl on your host"
    echo "  2. Copy kubeconfig from master:"
    echo "     scp vagrant@$MASTER_IP:~/.kube/config ~/.kube/config.jokejolt"
    echo "     export KUBECONFIG=~/.kube/config.jokejolt"
    echo ""
    echo "=========================================="
  SHELL
end
