provider "kubernetes" {
  version = "~> 1.11.2"
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.main.token
  load_config_file       = false
}

provider "helm" {
  version = "~> 1.2.2"
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.main.token
    load_config_file       = false
  }
}

resource "kubernetes_service_account" "oidc" {
  metadata {
    name = "aws-node"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.oidc.arn
    }
  }
}