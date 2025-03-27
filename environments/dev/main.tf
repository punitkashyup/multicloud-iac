terraform {
  required_version = ">= 1.0.0"
  required_providers {
    # Always include base providers
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration will be provided during initialization
  backend "azurerm" {}
  # backend "s3" {}
  # backend "local" {}
}

# Configure AWS provider only when needed
provider "aws" {
  region = var.aws_region

  # Skip AWS provider configuration when using Azure
  skip_credentials_validation = var.cloud_provider == "azure" ? true : false
  skip_requesting_account_id  = var.cloud_provider == "azure" ? true : false
  skip_metadata_api_check     = var.cloud_provider == "azure" ? true : false
  
  default_tags {
    tags = {
      Environment = local.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  cloud_provider = var.cloud_provider # "aws" or "azure"
  environment    = terraform.workspace != "default" ? terraform.workspace : "dev"
  
  # Dynamic resource group name using project_name and environment
  resource_group_name = "rg-${var.project_name}-${local.environment}"
}

# AWS Network Module - using count conditional
module "aws_network" {
  source = "../../modules/aws/vpc"
  count  = local.cloud_provider == "aws" ? 1 : 0
  
  name        = "${var.project_name}-${local.environment}-network"
  cidr_block  = var.network_cidr
  environment = local.environment
  tags        = var.resource_tags
}

# Azure Network Module - using count conditional
module "azure_network" {
  source = "../../modules/azure/vnet"
  count  = local.cloud_provider == "azure" ? 1 : 0
  
  name              = "${var.project_name}-${local.environment}-network"
  cidr_block        = var.network_cidr
  environment       = local.environment
  location          = var.azure_location
  tags              = var.resource_tags
  resource_group_name = local.resource_group_name
}

# AWS Kubernetes cluster - using count conditional
module "aws_kubernetes_cluster" {
  source = "../../modules/aws/eks"
  count  = local.cloud_provider == "aws" ? 1 : 0
  
  # Common parameters
  cluster_name       = "${var.project_name}-${local.environment}"
  environment        = local.environment
  resource_tags      = var.resource_tags
  
  # Network parameters
  subnet_ids         = module.aws_network[0].subnet_ids
  vpc_id             = module.aws_network[0].vpc_id
  
  # Provider-specific parameters
  node_count         = var.node_count
  node_instance_type = var.node_instance_type
  kubernetes_version = var.kubernetes_version
}

# Azure Kubernetes cluster - using count conditional
module "azure_kubernetes_cluster" {
  source = "../../modules/azure/aks"
  count  = local.cloud_provider == "azure" ? 1 : 0
  
  # Common parameters
  cluster_name       = "${var.project_name}-${local.environment}"
  environment        = local.environment
  resource_tags      = var.resource_tags
  
  # Network parameters
  subnet_ids         = module.azure_network[0].subnet_ids
  
  # Provider-specific parameters
  node_count         = var.node_count
  node_instance_type = var.node_instance_type
  kubernetes_version = var.kubernetes_version
  location           = var.azure_location
  resource_group_name = local.resource_group_name
}

# Configure Kubernetes provider with cluster credentials
provider "kubernetes" {
  host = local.cloud_provider == "aws" ? (
    length(module.aws_kubernetes_cluster) > 0 ? module.aws_kubernetes_cluster[0].endpoint : null
  ) : (
    length(module.azure_kubernetes_cluster) > 0 ? module.azure_kubernetes_cluster[0].host : null
  )
  
  cluster_ca_certificate = local.cloud_provider == "aws" ? (
    length(module.aws_kubernetes_cluster) > 0 ? base64decode(module.aws_kubernetes_cluster[0].cluster_ca_certificate) : null
  ) : (
    length(module.azure_kubernetes_cluster) > 0 ? base64decode(module.azure_kubernetes_cluster[0].cluster_ca_certificate) : null
  )
  
  dynamic "exec" {
    for_each = local.cloud_provider == "aws" && length(module.aws_kubernetes_cluster) > 0 ? [1] : []
    content {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.aws_kubernetes_cluster[0].cluster_name]
      command     = "aws"
    }
  }

  client_certificate = local.cloud_provider == "azure" && length(module.azure_kubernetes_cluster) > 0 ? base64decode(module.azure_kubernetes_cluster[0].client_certificate) : null
  client_key = local.cloud_provider == "azure" && length(module.azure_kubernetes_cluster) > 0 ? base64decode(module.azure_kubernetes_cluster[0].client_key) : null
}

# Configure Helm provider with cluster credentials
provider "helm" {
  kubernetes {
    host = local.cloud_provider == "aws" ? (
      length(module.aws_kubernetes_cluster) > 0 ? module.aws_kubernetes_cluster[0].endpoint : null
    ) : (
      length(module.azure_kubernetes_cluster) > 0 ? module.azure_kubernetes_cluster[0].host : null
    )
    
    cluster_ca_certificate = local.cloud_provider == "aws" ? (
      length(module.aws_kubernetes_cluster) > 0 ? base64decode(module.aws_kubernetes_cluster[0].cluster_ca_certificate) : null
    ) : (
      length(module.azure_kubernetes_cluster) > 0 ? base64decode(module.azure_kubernetes_cluster[0].cluster_ca_certificate) : null
    )
    
    dynamic "exec" {
      for_each = local.cloud_provider == "aws" && length(module.aws_kubernetes_cluster) > 0 ? [1] : []
      content {
        api_version = "client.authentication.k8s.io/v1beta1"
        args        = ["eks", "get-token", "--cluster-name", module.aws_kubernetes_cluster[0].cluster_name]
        command     = "aws"
      }
    }

    client_certificate = local.cloud_provider == "azure" && length(module.azure_kubernetes_cluster) > 0 ? base64decode(module.azure_kubernetes_cluster[0].client_certificate) : null
    client_key = local.cloud_provider == "azure" && length(module.azure_kubernetes_cluster) > 0 ? base64decode(module.azure_kubernetes_cluster[0].client_key) : null
  }
}

# Add Helm charts for MongoDB and Kafka
module "data_services" {
  source = "../../modules/kubernetes/helm-charts"
  
  count = var.deploy_data_services ? 1 : 0
  
  depends_on = [
    module.aws_kubernetes_cluster,
    module.azure_kubernetes_cluster
  ]
  
  environment      = local.environment
  create_namespace = true
  
  # MongoDB configuration
  mongodb_enabled     = var.mongodb_enabled
  mongodb_namespace   = var.mongodb_namespace
  mongodb_chart_version = var.mongodb_chart_version
  mongodb_values      = var.mongodb_values
  
  # Kafka configuration
  kafka_enabled      = var.kafka_enabled
  kafka_namespace    = var.kafka_namespace
  kafka_chart_version = var.kafka_chart_version
  kafka_values       = var.kafka_values
}

# Output cluster information
output "kubernetes_cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value = local.cloud_provider == "aws" ? (
    length(module.aws_kubernetes_cluster) > 0 ? module.aws_kubernetes_cluster[0].endpoint : null
  ) : (
    length(module.azure_kubernetes_cluster) > 0 ? module.azure_kubernetes_cluster[0].host : null
  )
  sensitive = true
}

output "kubernetes_cluster_name" {
  description = "The name of the Kubernetes cluster"
  value = local.cloud_provider == "aws" ? (
    length(module.aws_kubernetes_cluster) > 0 ? module.aws_kubernetes_cluster[0].cluster_name : null
  ) : (
    length(module.azure_kubernetes_cluster) > 0 ? module.azure_kubernetes_cluster[0].cluster_name : null
  )
}

output "resource_group_name" {
  description = "The name of the resource group (Azure only)"
  value = local.cloud_provider == "azure" ? local.resource_group_name : null
}

output "mongodb_connection_string" {
  description = "MongoDB connection string"
  value = var.deploy_data_services && var.mongodb_enabled && length(module.data_services) > 0 ? module.data_services[0].mongodb_connection_string : null
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers"
  value = var.deploy_data_services && var.kafka_enabled && length(module.data_services) > 0 ? module.data_services[0].kafka_bootstrap_servers : null
}