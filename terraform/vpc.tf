resource "aws_vpc" "main" {
  cidr_block         = "10.5.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "testing"
    environment = "testing"
    "kubernetes.io/cluster/testing" = "shared"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "control-plane" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)

  tags = {
    Name = format("testing-%02d",count.index + 1)
    environment = "testing"
    az = data.aws_availability_zones.available.names[count.index]
    "kubernetes.io/cluster/testing" = "shared"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    environment = "testing"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.control-plane[0].id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    environment = "testing"
    exposition = "public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    environment = "testing"
    exposition = "private"
  }
}

resource "aws_subnet" "worker" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id            = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + length(data.aws_availability_zones.available.names))
  map_public_ip_on_launch = true

  tags = {
    Name = format("testing-ng-%02d",count.index + 1)
    environment = "testing"
    az = data.aws_availability_zones.available.names[count.index]
    "kubernetes.io/cluster/testing" = "shared"
  }
}

resource "aws_route_table_association" "worker" {
  count = length(aws_subnet.worker)
  subnet_id      = aws_subnet.worker[count.index].id
  route_table_id = aws_route_table.public.id
}