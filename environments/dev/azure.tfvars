# Cloud Provider Selection
cloud_provider     = "azure"

# Common Variables
project_name        = "sparrow-app"
network_cidr        = "10.0.0.0/16"
node_count          = 2
kubernetes_version  = "1.30.10"
kubernetes_namespace = "application"

# Azure-specific Configuration
azure_location      = "eastus"
node_instance_type  = "Standard_B4ms"

# Application Configuration
app_name           = "sample-app"
app_version        = "1.0.0"
app_replicas       = 2
app_container_image = "nginx:latest"
app_container_port  = 80
app_resource_limits = {
  cpu    = "500m"
  memory = "512Mi"
}
app_resource_requests = {
  cpu    = "250m"
  memory = "256Mi"
}

# Resource Tags
resource_tags = {
  Owner       = "DevOps"
  Project     = "Sparrow"
  Environment = "Development"
  CostCenter  = "IT-123"
  ManagedBy   = "Terraform"
}

# Data Services Configuration
deploy_data_services = true

# MongoDB Configuration
mongodb_enabled = true
mongodb_namespace = "mongodb"
mongodb_values = {
  "auth.username" = "admin"
  "auth.database" = "admin"
  "replicaCount" = "3"
  "persistence.enabled" = "true"
  "persistence.size" = "50Gi"
  "metrics.enabled" = "true"
}

# Kafka Configuration
kafka_enabled = true
kafka_namespace = "kafka"
kafka_values = {
  "replicaCount" = "3"
  "persistence.enabled" = "true"
  "persistence.size" = "100Gi"
  "metrics.enabled" = "true"
  "externalAccess.enabled" = "false"  # Set to true if you need external access
}

nginx_ingress_enabled = true
nginx_ingress_chart_version = "11.6.12"
cert_manager_enabled = true
cert_manager_chart_version = "1.17.1"