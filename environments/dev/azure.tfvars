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