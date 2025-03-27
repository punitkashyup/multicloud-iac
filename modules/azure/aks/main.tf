resource "azurerm_resource_group" "main" {
  name     = "rg-${var.cluster_name}"
  location = var.location
  tags     = merge(var.resource_tags, { Environment = var.environment })
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.node_instance_type
    vnet_subnet_id      = var.subnet_ids[0]
    min_count           = 1
    max_count           = var.node_count * 2
    max_pods            = 100
    os_disk_size_gb     = 128
    
    tags = merge(var.resource_tags, {
      Environment = var.environment
      NodePool    = "default"
    })
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
    service_cidr       = "10.100.0.0/16"
    dns_service_ip     = "10.100.0.10"
  }

  tags = merge(var.resource_tags, {
    Environment = var.environment
    Managed     = "terraform"
  })

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

# Add a node pool
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = var.node_instance_type
  node_count           = var.node_count
  vnet_subnet_id       = var.subnet_ids[0]
  mode                 = "User"
  min_count           = 1
  max_count           = var.node_count * 2
  max_pods            = 100
  os_disk_size_gb     = 128
  
  tags = merge(var.resource_tags, {
    Environment = var.environment
    NodePool    = "user"
  })

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}