output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.main[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}