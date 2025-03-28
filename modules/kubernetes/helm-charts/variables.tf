variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_namespace" {
  description = "Whether to create Kubernetes namespaces"
  type        = bool
  default     = true
}

variable "mongodb_namespace" {
  description = "Kubernetes namespace for MongoDB"
  type        = string
  default     = "mongodb"
}

variable "kafka_namespace" {
  description = "Kubernetes namespace for Kafka"
  type        = string
  default     = "kafka"
}

variable "mongodb_values" {
  description = "Custom values for MongoDB Helm chart"
  type        = map(any)
  default     = {}
}

variable "kafka_values" {
  description = "Custom values for Kafka (Bitnami) Helm chart"
  type        = map(any)
  default     = {}
}

variable "mongodb_chart_version" {
  description = "Version of the MongoDB Helm chart"
  type        = string
  default     = "13.9.2"  # Update to the latest stable version as needed
}

variable "kafka_chart_version" {
  description = "Version of the Kafka Helm chart"
  type        = string
  default     = "22.1.5"  # Update to the latest stable version as needed
}

variable "mongodb_enabled" {
  description = "Whether to deploy MongoDB"
  type        = bool
  default     = true
}

variable "kafka_enabled" {
  description = "Whether to deploy Kafka"
  type        = bool
  default     = true
}
# Nginx Ingress Controller variables
variable "nginx_ingress_enabled" {
  description = "Whether to deploy Nginx Ingress Controller"
  type        = bool
  default     = false
}

variable "nginx_ingress_namespace" {
  description = "Kubernetes namespace for Nginx Ingress Controller"
  type        = string
  default     = "ingress-nginx"
}

variable "nginx_ingress_chart_version" {
  description = "Version of the Nginx Ingress Helm chart"
  type        = string
  default     = "4.7.1"  # Update to the latest stable version as needed
}

variable "nginx_ingress_values" {
  description = "Custom values for Nginx Ingress Helm chart"
  type        = map(any)
  default     = {}
}

# Cert Manager variables
variable "cert_manager_enabled" {
  description = "Whether to deploy Cert Manager"
  type        = bool
  default     = false
}

variable "cert_manager_namespace" {
  description = "Kubernetes namespace for Cert Manager"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_chart_version" {
  description = "Version of the Cert Manager Helm chart"
  type        = string
}

variable "cert_manager_values" {
  description = "Custom values for Cert Manager Helm chart"
  type        = map(any)
  default     = {}
}