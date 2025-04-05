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
mongodb_autoscaling_enabled     = true
mongodb_min_replicas            = 3
mongodb_max_replicas            = 7
mongodb_target_cpu_percentage   = 70
mongodb_connection_threshold    = 500  # Scale based on connection count
mongodb_storage_autoscaling     = true
mongodb_max_storage             = "10Gi"

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

# Monitoring Configuration
monitoring_enabled = true
prometheus_retention_time = "7d"
prometheus_storage_size = "50Gi"
alert_manager_storage_size = "5Gi"
monitoring_chart_version = "45.7.1"
email_to = "punit.kumar@techdome.net.in"
base_domain = "example.com"