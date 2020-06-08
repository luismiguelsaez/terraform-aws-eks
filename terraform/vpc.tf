# Create main VPC
resource "aws_vpc" "main" {
  cidr_block         = "10.5.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.defaults.environment
    environment = var.defaults.environment
    "kubernetes.io/cluster/${var.defaults.environment}" = "shared"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create EKS private subnets
resource "aws_subnet" "private" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)

  tags = {
    Name = format("%s-%02d", var.defaults.environment, count.index + 1)
    environment = var.defaults.environment
    az = data.aws_availability_zones.available.names[count.index]
    "kubernetes.io/cluster/${var.defaults.environment}" = "shared"
  }
}

# Create EKS public subnets
resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(data.aws_availability_zones.available.names))
  #map_public_ip_on_launch = true

  tags = {
    Name = format("%s-ng-%02d", var.defaults.environment, count.index + 1)
    environment = var.defaults.environment
    az = data.aws_availability_zones.available.names[count.index]
    "kubernetes.io/cluster/${var.defaults.environment}" = "shared"
  }
}

# Create IGW
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    environment = var.defaults.environment
    exposition = "public"
  }
}

# Create EIP and NGW
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    environment = var.defaults.environment
    exposition = "private"
    az = data.aws_availability_zones.available.names[0]
  }
}

# Create private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    environment = var.defaults.environment
    exposition = "private"
  }
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    environment = var.defaults.environment
    exposition = "private"
  }
}

# Assign private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Assign public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}