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
  default     = "t3.medium" # For AWS; Azure will map to an equivalent size
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
  type        = string
  default     = "1.26"
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