variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "node_count" {
  description = "Number of nodes in the Kubernetes cluster"
  type        = number
}

variable "node_instance_type" {
  description = "VM size for Kubernetes nodes"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use"
  type        = string
  default     = "1.26.0"
}