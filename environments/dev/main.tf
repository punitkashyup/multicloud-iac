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
  
  # Optional: Set this if you want to completely skip AWS provider when using Azure
  # alias = var.cloud_provider == "azure" ? "unused" : "default"

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
  resource_group_name = local.resource_group_name  # Use the dynamic name based on project name
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
  resource_group_name = local.resource_group_name  # Use the dynamic name based on project name
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

  dynamic "client_certificate" {
    for_each = local.cloud_provider == "azure" && length(module.azure_kubernetes_cluster) > 0 ? [1] : []
    content {
      data = module.azure_kubernetes_cluster[0].client_certificate
    }
  }

  dynamic "client_key" {
    for_each = local.cloud_provider == "azure" && length(module.azure_kubernetes_cluster) > 0 ? [1] : []
    content {
      data = module.azure_kubernetes_cluster[0].client_key
    }
  }
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

    dynamic "client_certificate" {
      for_each = local.cloud_provider == "azure" && length(module.azure_kubernetes_cluster) > 0 ? [1] : []
      content {
        data = module.azure_kubernetes_cluster[0].client_certificate
      }
    }

    dynamic "client_key" {
      for_each = local.cloud_provider == "azure" && length(module.azure_kubernetes_cluster) > 0 ? [1] : []
      content {
        data = module.azure_kubernetes_cluster[0].client_key
      }
    }
  }
}

# module "application_deployment" {
#   source = "../../modules/kubernetes/app-deployment"
  
#   depends_on = [
#     module.aws_kubernetes_cluster,
#     module.azure_kubernetes_cluster
#   ]
  
#   app_name             = var.app_name
#   app_version          = var.app_version
#   app_replicas         = var.app_replicas
#   app_container_image  = var.app_container_image
#   app_container_port   = var.app_container_port
#   environment          = local.environment
#   namespace            = var.kubernetes_namespace
#   resource_limits      = var.app_resource_limits
#   resource_requests    = var.app_resource_requests
# }