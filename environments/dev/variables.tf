variable "cloud_provider" {
  description = "The cloud provider to use (aws or azure)"
  type        = string
  default     = "aws"

  validation {
    condition     = contains(["aws", "azure"], var.cloud_provider)
    error_message = "Valid values for cloud_provider are: aws, azure."
  }
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "multicloud-app"
}

variable "aws_region" {
  description = "The AWS region to deploy resources to"
  type        = string
  default     = "us-west-2"
}

variable "azure_location" {
  description = "The Azure region to deploy resources to"
  type        = string
  default     = "eastus"
}

variable "resource_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    Owner       = "DevOps"
    Project     = "MultiCloud"
    CostCenter  = "IT-123"
  }
}

variable "network_cidr" {
  description = "CIDR block for the VPC/VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_count" {
  description = "Number of nodes in the Kubernetes cluster"
  type        = number
  default     = 2
}

variable "node_instance_type" {
  description = "Instance type for Kubernetes nodes"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
  default     = "application"
}

variable "app_name" {
  description = "Name of the application to deploy"
  type        = string
  default     = "sample-app"
}

variable "app_version" {
  description = "Version of the application to deploy"
  type        = string
  default     = "1.0.0"
}

variable "app_replicas" {
  description = "Number of application replicas to deploy"
  type        = number
  default     = 2
}

variable "app_container_image" {
  description = "Container image for the application"
  type        = string
  default     = "nginx:latest"
}

variable "app_container_port" {
  description = "Container port for the application"
  type        = number
  default     = 80
}

variable "app_resource_limits" {
  description = "Resource limits for the application containers"
  type        = map(string)
  default     = {
    cpu    = "500m"
    memory = "512Mi"
  }
}

variable "app_resource_requests" {
  description = "Resource requests for the application containers"
  type        = map(string)
  default     = {
    cpu    = "250m"
    memory = "256Mi"
  }
}

# Data Services Configuration
variable "deploy_data_services" {
  description = "Whether to deploy MongoDB and Kafka"
  type        = bool
  default     = true
}

variable "mongodb_enabled" {
  description = "Whether to deploy MongoDB"
  type        = bool
  default     = true
}

variable "mongodb_namespace" {
  description = "Kubernetes namespace for MongoDB"
  type        = string
  default     = "mongodb"
}

variable "mongodb_chart_version" {
  description = "Version of the MongoDB Helm chart"
  type        = string
  default     = "13.9.2"  # Update as needed
}

variable "mongodb_values" {
  description = "Custom values for MongoDB Helm chart"
  type        = map(any)
  default     = {}
}

variable "kafka_enabled" {
  description = "Whether to deploy Kafka"
  type        = bool
  default     = true
}

variable "kafka_namespace" {
  description = "Kubernetes namespace for Kafka"
  type        = string
  default     = "kafka"
}

variable "kafka_chart_version" {
  description = "Version of the Kafka Helm chart"
  type        = string
  default     = "22.1.5"  # Update as needed
}

variable "kafka_values" {
  description = "Custom values for Kafka Helm chart"
  type        = map(any)
  default     = {}
}

variable "nginx_ingress_enabled" {
  description = "Whether to deploy Nginx Ingress Controller"
  type        = bool
  default     = false
}

variable "nginx_ingress_chart_version" {
  description = "Version of the Nginx Ingress Controller Helm chart"
  type        = string
}

variable "cert_manager_enabled" {
  description = "Whether to deploy Cert Manager"
  type        = bool
  default     = false
}

variable "cert_manager_chart_version" {
  description = "Version of the Cert Manager Helm chart"
  type        = string
}