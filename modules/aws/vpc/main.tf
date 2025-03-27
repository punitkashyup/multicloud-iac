resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = merge(
    var.tags,
    {
      Name = var.name
      Environment = var.environment
    }
  )
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  count = min(length(data.aws_availability_zones.available.names), 3)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-${count.index}"
      Environment = var.environment
      "kubernetes.io/role/elb" = "1"
    }
  )
}

resource "aws_subnet" "private" {
  count = min(length(data.aws_availability_zones.available.names), 3)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index + 100)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-${count.index}"
      Environment = var.environment
      "kubernetes.io/role/internal-elb" = "1"
    }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-igw"
      Environment = var.environment
    }
  )
}

resource "aws_eip" "nat" {
  count = 1
  vpc   = true
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-eip-${count.index}"
      Environment = var.environment
    }
  )
}

resource "aws_nat_gateway" "main" {
  count         = 1
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-nat-${count.index}"
      Environment = var.environment
    }
  )
  
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-public-rt"
      Environment = var.environment
    }
  )
}

resource "aws_route_table" "private" {
  count  = 1
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[0].id
  }
  
  tags = merge(
    var.tags,
    {
      Name = "${var.name}-private-rt"
      Environment = var.environment
    }
  )
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}