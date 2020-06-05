### Create EKS cluster role
resource "aws_iam_role" "eks" {
  name = format("eks-cluster-%s", var.defaults.environment)

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

### Create EKS nodes role
resource "aws_iam_role" "node" {
  name = format("eks-nodes-%s", var.defaults.environment)

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

### Enable OIDC provider
data "external" "thumbprint" {
  program = [ "./scripts/get-oidc-thumbprint.sh", data.aws_region.current.name ]
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = [ "sts.amazonaws.com"]
  # Get thumbprint: https://medium.com/@marcincuber/amazon-eks-with-oidc-provider-iam-roles-for-kubernetes-services-accounts-59015d15cb0c
  thumbprint_list = [ data.external.thumbprint.result.thumbprint ]
  url             = aws_eks_cluster.main.identity.0.oidc.0.issuer
}

data "aws_iam_policy_document" "oidc" {
  statement {
    actions = [ "sts:AssumeRoleWithWebIdentity" ]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub"
      values   = [ "system:serviceaccount:kube-system:aws-node" ]
    }

    principals {
      identifiers = [ aws_iam_openid_connect_provider.main.arn ]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "oidc" {
  name               = format("eks-cluster-oidc-%s", var.defaults.environment)
  assume_role_policy = data.aws_iam_policy_document.oidc.json
}