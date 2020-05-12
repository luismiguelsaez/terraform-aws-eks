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

resource "aws_subnet" "main" {
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

resource "aws_subnet" "node-group" {
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

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.node-group)
  subnet_id      = aws_subnet.node-group[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "main" {
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow all from inside security-group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    self = true
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  tags = {
    environment = "testing"
  }
}

resource "aws_iam_role" "eks" {
  name = "eks-cluster-testing"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks-service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role" "node" {
  name = "eks-cluster-testing-node"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-node-worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "eks-node-registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_eks_cluster" "main" {
  name     = "testing"
  role_arn = aws_iam_role.eks.arn
  version = "1.16"

  vpc_config {
    subnet_ids = aws_subnet.main.*.id
    security_group_ids = [ aws_security_group.main.id ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-cluster",
    "aws_iam_role_policy_attachment.eks-service"
  ]
}

data "aws_eks_cluster_auth" "main" {
  name = "testing"
}

resource "aws_key_pair" "node-group" {
  count = var.node-group.remote-access ? 1 : 0

  key_name   = "testing"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClk2d4WxqTh7/P6MkDF5Ytyqe4kpJ4BK44J64xI9hINVwE+Bb2Dujej5FSmtZHwYirNX4JxUoCkwIuTphpo6zeqzOxq/Wz6bXm6CCoZ2b+MUTDrsCeBg7vpCeLcCa4DvdTU6ejXr3eqfWCY8NSIOIOdNFL/vw3nbdSpM7hb0DYcihtI8BDY5FJAV2iBCV31Eiq5/gXGBI0pDzpSPqz3euau9eDtjBkZGwq4VXkWSsYFYkTZzu4/ejA+B4yZo459e7gFOKe4a2L1wJ23HDBceUH6Y3ieeFiF9VQ0u/egTCEYkmL8p//u2nuU3ifEcAL15P9BLlBmrZjg725TZlocH0v"
}

resource "aws_security_group" "node-group" {
  count = var.node-group.remote-access ? 1 : 0

  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "testing"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = aws_subnet.node-group.*.id
  version = "1.16"

  dynamic "remote_access" {
    for_each = var.node-group.remote-access ? [ "a" ] : []
    content {
      ec2_ssh_key = "testing"
      source_security_group_ids = [ aws_security_group.node-group.id ]
    }
  }

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 2
  }

  instance_types = [ "t3.medium" ]

  depends_on = [
    aws_iam_role_policy_attachment.eks-node-worker,
    aws_iam_role_policy_attachment.eks-node-cni,
    aws_iam_role_policy_attachment.eks-node-registry
  ]

  tags = {
    "kubernetes.io/cluster/testing" = "owned"
  }
}