output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "virtual_network_id" {
  description = "ID of the VNet"
  value       = azurerm_virtual_network.main.id
}

output "virtual_network_name" {
  description = "Name of the VNet"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = concat(azurerm_subnet.private[*].id, azurerm_subnet.public[*].id)
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = azurerm_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = azurerm_subnet.public[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = azurerm_nat_gateway.main.id
}