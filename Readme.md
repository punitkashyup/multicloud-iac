# Multi-Cloud Kubernetes Infrastructure with Terraform

This repository provides a Terraform solution for deploying Kubernetes clusters across multiple cloud providers (AWS EKS and Azure AKS) while maintaining environment isolation and following infrastructure-as-code best practices.

## Features

- Multi-cloud support (AWS EKS and Azure AKS)
- Environment isolation using Terraform workspaces
- Modular design for maximum reusability
- Remote state management with locking
- CI/CD pipeline integration examples
- Kubernetes application deployment

## Prerequisites

- Terraform v1.0.0+
- AWS CLI configured (for AWS deployments)
- Azure CLI configured (for Azure deployments)
- kubectl for Kubernetes operations

## Getting Started

### Local Deployment

1. Set up your cloud provider credentials:

   **For AWS:**
   ```bash
   export AWS_ACCESS_KEY_ID="your_access_key"
   export AWS_SECRET_ACCESS_KEY="your_secret_key"
   export AWS_REGION="us-west-2"
For Azure:

# Login to Azure (if not already logged in)
az login

# Set subscription (if you have multiple subscriptions)
# az account set --subscription "Your-Subscription-Id"

# Create Resource Group
```bash
az group create --name terraform-state-rg --location centralindia
```

# Create Storage Account
```bash
az storage account create --name techdometerraformstate --resource-group terraform-state-rg --location eastus --sku Standard_LRS
```
# Get Storage Account Key
```bash
STORAGE_KEY=$(az storage account keys list --resource-group terraform-state-rg --account-name techdometerraformstate --query "[0].value" -o tsv)
```

# Create Storage Container
```bash
az storage container create --name tfstate --account-name techdometerraformstate --account-key ""
```

Navigate to your desired environment directory:

cd environments/dev
Initialize Terraform with the appropriate backend:

For AWS S3 backend:

```bash
terraform init -backend-config=../../backend/s3.tf
```
For Azure backend:
```bash
terraform init -backend-config=../../backend/azurerm.tf
```
For local backend (not recommended for production):

```bash
terraform init -backend-config=../../backend/local.tf
```

Create and select a workspace:
```bash
terraform workspace new dev
```
# Or select an existing workspace
```bash
terraform workspace select dev
```
Deploy the infrastructure:

# For AWS
```bash
terraform plan -var-file=terraform.tfvars -var="cloud_provider=aws"
terraform apply -var-file=terraform.tfvars -var="cloud_provider=aws"
```

# For Azure
```bash
terraform plan -var-file=terraform.tfvars -var="cloud_provider=azure"
terraform apply -var-file=terraform.tfvars -var="cloud_provider=azure"
```


CI/CD Pipeline
This repository includes example CI/CD pipeline configurations for Azure DevOps. See the pipeline definition files in the repository for implementation details.

Module Structure
AWS Modules: Configuration for EKS clusters and supporting infrastructure
Azure Modules: Configuration for AKS clusters and supporting infrastructure
Kubernetes Modules: Application deployment configurations
State Management
By default, this project is configured to use remote state storage with locking mechanisms:

AWS: S3 bucket with DynamoDB locking
Azure: Azure Storage with blob locking
Contributing
Please follow standard Git workflow:

Fork the repository
Create a feature branch
Submit a pull request