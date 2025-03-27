resource "azurerm_resource_group" "main" {
  name     = "rg-${var.name}"
  location = var.location
  tags     = merge(var.tags, { Environment = var.environment })
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name}"
  address_space       = [var.cidr_block]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = merge(var.tags, { Environment = var.environment })
}

resource "azurerm_subnet" "public" {
  count                = 3
  name                 = "snet-public-${count.index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.cidr_block, 8, count.index)]
}

resource "azurerm_subnet" "private" {
  count                = 3
  name                 = "snet-private-${count.index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.cidr_block, 8, count.index + 10)]
}

resource "azurerm_public_ip" "nat" {
  name                = "pip-${var.name}-nat"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.tags, { Environment = var.environment })
}

resource "azurerm_nat_gateway" "main" {
  name                    = "nat-${var.name}"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = merge(var.tags, { Environment = var.environment })
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count          = length(azurerm_subnet.private)
  subnet_id      = azurerm_subnet.private[count.index].id
  nat_gateway_id = azurerm_nat_gateway.main.id
}