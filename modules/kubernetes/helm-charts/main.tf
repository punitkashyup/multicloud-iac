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