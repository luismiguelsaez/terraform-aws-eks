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

resource "aws_eks_cluster" "main" {
  name     = "testing"
  role_arn = aws_iam_role.eks.arn
  version = "1.16"

  vpc_config {
    subnet_ids = aws_subnet.control-plane.*.id
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
  subnet_ids      = aws_subnet.worker.*.id
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