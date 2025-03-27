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