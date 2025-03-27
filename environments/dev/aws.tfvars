# Cloud Provider Selection
cloud_provider     = "aws"

# Common Variables
project_name        = "multicloud-app"
network_cidr        = "10.0.0.0/16"
node_count          = 2
kubernetes_version  = "1.26"
kubernetes_namespace = "application"

# AWS-specific Configuration
aws_region          = "us-west-2"
node_instance_type  = "t3.medium"

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
  Project     = "MultiCloud"
  CostCenter  = "IT-123"
  ManagedBy   = "Terraform"
  Cloud       = "AWS"
}