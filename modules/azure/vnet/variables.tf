variable "name" {
  description = "The name of the VNet"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}
variable "resource_group_name" {
  description = "Name of the resource group to create resources in"
  type        = string
}
variable "cidr_block" {
  description = "CIDR block for the VNet"
  type        = string
  default     = "10.0.0.0/16"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}