# Create namespaces if enabled
resource "kubernetes_namespace" "mongodb" {
  count = var.create_namespace && var.mongodb_enabled ? 1 : 0

  metadata {
    name = var.mongodb_namespace
    
    labels = {
      name = var.mongodb_namespace
      environment = var.environment
      managed-by = "terraform"
    }
  }
}

resource "kubernetes_namespace" "kafka" {
  count = var.create_namespace && var.kafka_enabled ? 1 : 0

  metadata {
    name = var.kafka_namespace
    
    labels = {
      name = var.kafka_namespace
      environment = var.environment
      managed-by = "terraform"
    }
  }
}

# Add MongoDB Helm repository
resource "helm_release" "mongodb" {
  count      = var.mongodb_enabled ? 1 : 0
  depends_on = [kubernetes_namespace.mongodb]

  name       = "mongodb"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "mongodb"
  version    = var.mongodb_chart_version
  namespace  = var.mongodb_namespace

  # Default values with sensible MongoDB configuration
  set {
    name  = "auth.enabled"
    value = "true"
  }
  
  set {
    name  = "architecture"
    value = "replicaset"
  }

  # For production, enable persistence
  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "8Gi"
  }

  # Set resource limits based on environment
  set {
    name  = "resources.requests.memory"
    value = var.environment == "prod" ? "1Gi" : "512Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = var.environment == "prod" ? "500m" : "250m"
  }

  # Apply any custom values provided
  dynamic "set" {
    for_each = var.mongodb_values
    content {
      name  = set.key
      value = set.value
    }
  }
}

# Add Kafka Helm release
resource "helm_release" "kafka" {
  count      = var.kafka_enabled ? 1 : 0
  depends_on = [kubernetes_namespace.kafka]

  name       = "kafka"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "kafka"
  version    = var.kafka_chart_version
  namespace  = var.kafka_namespace

  # Default values with sensible Kafka configuration
  set {
    name  = "replicaCount"
    value = var.environment == "prod" ? 3 : 1
  }

  # For production, enable persistence
  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "8Gi"
  }

  # Configure Zookeeper
  set {
    name  = "zookeeper.enabled"
    value = "false"
  }

  # Set resource limits based on environment
  set {
    name  = "resources.requests.memory"
    value = var.environment == "prod" ? "2Gi" : "1Gi"
  }

  set {
    name  = "resources.requests.cpu"
    value = var.environment == "prod" ? "500m" : "250m"
  }

  # Apply any custom values provided
  dynamic "set" {
    for_each = var.kafka_values
    content {
      name  = set.key
      value = set.value
    }
  }
}

# Create namespaces if enabled
resource "kubernetes_namespace" "nginx_ingress" {
  count = var.create_namespace && var.nginx_ingress_enabled ? 1 : 0

  metadata {
    name = var.nginx_ingress_namespace
    
    labels = {
      name = var.nginx_ingress_namespace
      environment = var.environment
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.create_namespace && var.cert_manager_enabled ? 1 : 0

  metadata {
    name = var.cert_manager_namespace
    
    labels = {
      name = var.cert_manager_namespace
      environment = var.environment
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# Deploy Nginx web server# Deploy Nginx Ingress Controller
resource "helm_release" "nginx_ingress" {
  count      = var.nginx_ingress_enabled ? 1 : 0
  depends_on = [kubernetes_namespace.nginx_ingress]

  name       = "nginx-ingress"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "nginx-ingress-controller"
  version    = var.nginx_ingress_chart_version
  namespace  = var.nginx_ingress_namespace

  # Default values with sensible Nginx Ingress configuration
  # set {
  #   name  = "controller.replicaCount"
  #   value = var.environment == "prod" ? 3 : 1
  # }

  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  set {
    name  = "controller.metrics.serviceMonitor.enabled"
    value = "false"
  }

  # Set resource limits based on environment
  set {
    name  = "controller.resources.requests.memory"
    value = var.environment == "prod" ? "256Mi" : "128Mi"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = var.environment == "prod" ? "100m" : "50m"
  }

  # Apply any custom values provided
  dynamic "set" {
    for_each = var.nginx_ingress_values
    content {
      name  = set.key
      value = set.value
    }
  }
}

# Deploy Cert Manager
resource "helm_release" "cert_manager" {
  count      = var.cert_manager_enabled ? 1 : 0
  depends_on = [kubernetes_namespace.cert_manager]

  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_chart_version
  namespace  = var.cert_manager_namespace
  set {
    name  = "installCRDs"
    value = "true"
  }

  # Enable prometheus metrics
  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  # Set resource limits based on environment
  set {
    name  = "resources.requests.memory"
    value = var.environment == "prod" ? "256Mi" : "128Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = var.environment == "prod" ? "100m" : "50m"
  }

  # Apply any custom values provided
  dynamic "set" {
    for_each = var.cert_manager_values
    content {
      name  = set.key
      value = set.value
    }
  }
}