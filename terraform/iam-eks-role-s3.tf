resource "aws_iam_policy" "s3_test" {
  name        = format("%s-s3_test", var.defaults.environment)
  description = "S3 access test policy"
  policy      = file("aws/iam/policy/s3_test.json")
}

resource "aws_iam_role" "s3_test" {
   name = format("%s-s3_test", var.defaults.environment)
   assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:default:s3-test"
        }
      }
      Principal = {
        Federated = "${aws_iam_openid_connect_provider.main.arn}"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "s3_test" {
  role       = aws_iam_role.s3_test.name 
  policy_arn = aws_iam_policy.s3_test.arn
}

resource "kubernetes_service_account" "oidc" {
  metadata {
    name = "s3-test"
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.s3_test.arn
    }
  }
}