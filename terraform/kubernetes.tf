# ─── Kubernetes Namespace ────────────────────────────────────────────────────

resource "kubernetes_namespace" "production" {
  metadata {
    name = var.k8s_namespace

    labels = {
      name        = var.k8s_namespace
      environment = "production"
      managed-by  = "terraform"
    }
  }

  depends_on = [null_resource.cluster_ready]
}

# ─── Kubernetes Secret for Image Pull ─────────────────────────────────────────

resource "kubernetes_secret" "image_pull" {
  metadata {
    name      = "ghcr-secret"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          username = var.project_name
          password = "YOUR_GITHUB_TOKEN" // Use terraform vault or sensitive variable
          auth     = base64encode("${var.project_name}:YOUR_GITHUB_TOKEN")
        }
      }
    })
  }

  depends_on = [kubernetes_namespace.production]
}

# ─── Kubernetes Deployment ───────────────────────────────────────────────────

resource "kubernetes_deployment" "jokejolt" {
  metadata {
    name      = "jokejolt"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {
      app         = "jokejolt"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  spec {
    replicas = var.k8s_replicas

    selector {
      match_labels = {
        app = "jokejolt"
      }
    }

    template {
      metadata {
        labels = {
          app         = "jokejolt"
          environment = "production"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.image_pull.metadata[0].name
        }

        service_account_name = kubernetes_service_account.app.metadata[0].name

        container {
          name              = "jokejolt"
          image             = "${aws_ecr_repository.jokejolt.repository_url}:${var.k8s_image_tag}"
          image_pull_policy = "Always"

          port {
            container_port = var.k8s_container_port
            protocol       = "TCP"
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }

          env {
            name  = "PORT"
            value = tostring(var.k8s_container_port)
          }

          resources {
            requests = {
              cpu    = var.container_cpu_requests
              memory = var.container_memory_requests
            }
            limits = {
              cpu    = var.container_cpu_limits
              memory = var.container_memory_limits
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = var.k8s_container_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = var.k8s_container_port
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        termination_grace_period_seconds = 30
      }
    }
  }

  depends_on = [kubernetes_namespace.production, kubernetes_secret.image_pull]
}

# ─── Kubernetes Service ──────────────────────────────────────────────────────

resource "kubernetes_service" "jokejolt" {
  metadata {
    name      = "jokejolt"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {
      app         = "jokejolt"
      environment = "production"
      managed-by  = "terraform"
    }

    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type"            = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-scheme"          = "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.alb.id
    }
  }

  spec {
    selector = {
      app = "jokejolt"
    }

    type = "LoadBalancer"

    port {
      name        = "http"
      port        = 80
      target_port = var.k8s_container_port
      protocol    = "TCP"
    }
  }

  depends_on = [kubernetes_deployment.jokejolt]
}

# ─── Horizontal Pod Autoscaler ───────────────────────────────────────────────

resource "kubernetes_horizontal_pod_autoscaler_v2" "jokejolt" {
  metadata {
    name      = "jokejolt"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {
      app         = "jokejolt"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  spec {
    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.jokejolt.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type               = "Utilization"
          average_utilization = var.hpa_cpu_target_utilization
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type               = "Utilization"
          average_utilization = var.hpa_memory_target_utilization
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        policy {
          type           = "Percent"
          value          = 25
          period_seconds = 60
        }
      }

      scale_up {
        stabilization_window_seconds = 60
        policy {
          type           = "Percent"
          value          = 100
          period_seconds = 60
        }
        policy {
          type           = "Pods"
          value          = 4
          period_seconds = 60
        }
        select_policy = "Max"
      }
    }
  }

  depends_on = [kubernetes_deployment.jokejolt]
}

# ─── Pod Disruption Budget ───────────────────────────────────────────────────

resource "kubernetes_pod_disruption_budget" "jokejolt" {
  metadata {
    name      = "jokejolt-pdb"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {
      app         = "jokejolt"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  spec {
    min_available = 2

    selector {
      match_labels = {
        app = "jokejolt"
      }
    }
  }

  depends_on = [kubernetes_deployment.jokejolt]
}

# ─── Kubernetes Service Account ──────────────────────────────────────────────

resource "kubernetes_service_account" "app" {
  metadata {
    name      = "${var.project_name}-app"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {
      app         = "jokejolt"
      environment = "production"
      managed-by  = "terraform"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.application.arn
    }
  }

  depends_on = [kubernetes_namespace.production]
}

# ─── Network Policy ──────────────────────────────────────────────────────────

resource "kubernetes_network_policy" "jokejolt" {
  metadata {
    name      = "jokejolt-network-policy"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {
      app         = "jokejolt"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  spec {
    pod_selector {
      match_labels = {
        app = "jokejolt"
      }
    }

    policy_types = ["Ingress", "Egress"]

    ingress {
      ports {
        port     = tostring(var.k8s_container_port)
        protocol = "TCP"
      }
    }

    egress {
      to {
        namespace_selector {}
      }

      ports {
        port     = "443"
        protocol = "TCP"
      }
      ports {
        port     = "53"
        protocol = "UDP"
      }
      ports {
        port     = "53"
        protocol = "TCP"
      }
    }
  }

  depends_on = [kubernetes_namespace.production]
}

# ─── ConfigMap for Application Configuration ─────────────────────────────────

resource "kubernetes_config_map" "jokejolt" {
  metadata {
    name      = "${var.project_name}-config"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {
      app         = "jokejolt"
      environment = "production"
      managed-by  = "terraform"
    }
  }

  data = {
    NODE_ENV = "production"
    PORT     = tostring(var.k8s_container_port)
  }

  depends_on = [kubernetes_namespace.production]
}
