resource "aws_eks_cluster" "main" {
  name     = var.defaults.environment
  role_arn = aws_iam_role.eks.arn
  version = "1.16"

  vpc_config {
    subnet_ids = flatten([ aws_subnet.private.*.id ])
    security_group_ids = [ ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    "aws_iam_role_policy_attachment.eks-cluster",
    "aws_iam_role_policy_attachment.eks-service"
  ]
}

data "aws_eks_cluster_auth" "main" {
  name = var.defaults.environment
}

resource "aws_security_group_rule" "remote-access" {
  description       = "Allow SSH access for bastion instance"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [ "0.0.0.0/0" ]
  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.defaults.environment
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = flatten([ aws_subnet.private.*.id ])
  version = "1.16"

  remote_access {
    ec2_ssh_key = aws_key_pair.node-group.key_name
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
    "kubernetes.io/cluster/${var.defaults.environment}" = "owned"
  }
}