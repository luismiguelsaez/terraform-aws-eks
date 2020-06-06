locals {
  s3-sa-name      = "s3"
  s3-sa-namespace = "default"
}

resource "aws_iam_policy" "s3" {
  name        = format("%s-s3", var.defaults.environment)
  description = "S3 access test policy"
  policy      = file("aws/iam/policy/s3_test.json")
}

resource "aws_iam_role" "s3" {
   name = format("%s-s3", var.defaults.environment)
   assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:${local.s3-sa-namespace}:${local.s3-sa-name}"
        }
      }
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.main.arn}"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.s3.name 
  policy_arn = aws_iam_policy.s3.arn
}

resource "kubernetes_service_account" "oidc" {
  metadata {
    name = "s3"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.s3.arn
    }
  }
}