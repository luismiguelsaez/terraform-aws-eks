### Enable OIDC provider
data "external" "thumbprint" {
  program = [ "./scripts/get-oidc-thumbprint.sh", data.aws_region.current.name ]
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = [ "sts.amazonaws.com"]
  thumbprint_list = [ lower(data.external.thumbprint.result.thumbprint) ]
  url             = aws_eks_cluster.main.identity.0.oidc.0.issuer
}

#data "aws_iam_policy_document" "oidc" {
#  statement {
#    actions = [ "sts:AssumeRoleWithWebIdentity" ]
#    effect  = "Allow"
#
#    condition {
#      test     = "StringEquals"
#      variable = "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub"
#      values   = [ "system:serviceaccount:kube-system:aws-node" ]
#    }
#
#    principals {
#      identifiers = [ aws_iam_openid_connect_provider.main.arn ]
#      type        = "Federated"
#    }
#  }
#}
#
#resource "aws_iam_role" "oidc" {
#  name               = format("eks-cluster-oidc-%s", var.defaults.environment)
#  assume_role_policy = data.aws_iam_policy_document.oidc.json
#}