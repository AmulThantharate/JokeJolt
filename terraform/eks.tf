# ─── EKS Cluster ──────────────────────────────────────────────────────────────

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.21"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.cluster_version

  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  cluster_security_group_id = aws_security_group.cluster.id

  # Enable CloudWatch logging
  cluster_enabled_log_types = var.enable_cloudwatch_logs ? ["api", "audit", "authenticator", "controllerManager", "scheduler"] : []

  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_retention

  # Cluster tags
  cluster_tags = {
    "karpenter.sh/discovery" = "${var.project_name}-eks"
  }

  tags = {
    Name = "${var.project_name}-eks"
  }
}

# ─── EKS Managed Node Group ──────────────────────────────────────────────────

module "eks_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 19.21"

  name            = "${var.project_name}-node-group"
  cluster_name    = module.eks.cluster_name
  cluster_version = var.cluster_version

  subnet_ids = aws_subnet.private[*].id

  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  min_size     = var.node_group_min_size
  max_size     = var.node_group_max_size
  desired_size = var.node_group_desired_size

  instance_types = var.node_group_instance_types
  capacity_type  = "ON_DEMAND"

  disk_size = var.node_disk_size

  # Security group
  vpc_security_group_ids = [aws_security_group.node.id]

  # Enable auto-scaling
  use_custom_launch_template = false

  tags = {
    Name = "${var.project_name}-node-group"
  }
}

# ─── IAM Role for Service Accounts (IRSA) ────────────────────────────────────

module "eks_irsa" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 19.21"

  create = false
}

# IAM OIDC Provider for EKS
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [module.eks.cluster_oidc_issuer_certificate]
  url             = module.eks.cluster_oidc_issuer_url

  tags = {
    Name = "${var.project_name}-eks-oidc-provider"
  }
}

# ─── Kubernetes ConfigMap for aws-auth ───────────────────────────────────────

resource "kubectl_manifest" "aws_auth" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "aws-auth"
      namespace = "kube-system"
    }
    data = {
      mapRoles = yamlencode([
        {
          rolearn  = module.eks.cluster_primary_security_group_id
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        }
      ])
    }
  })

  depends_on = [module.eks]
}

# ─── WaitFor Cluster Ready ──────────────────────────────────────────────────

resource "null_resource" "cluster_ready" {
  triggers = {
    cluster_endpoint = module.eks.cluster_endpoint
  }

  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${module.eks.cluster_name}"
  }

  depends_on = [module.eks]
}
