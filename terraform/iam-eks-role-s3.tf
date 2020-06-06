locals {
  s3-sa-name      = "s3"
  s3-sa-namespace = "default"
  s3-bucket-name  = "testing-s3-k8s"
}

resource "aws_s3_bucket" "main" {
  bucket = local.s3-bucket-name
  acl    = "private"
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = templatefile(
    "aws/s3/policy/default.tpl",
    {
      bucket_name = local.s3-bucket-name,
      iam_role_id = aws_iam_role.s3.unique_id,
      user_arn    = data.aws_caller_identity.current.arn
    }
  )
}

resource "aws_iam_policy" "s3" {
  name        = format("%s-%s", var.defaults.environment, local.s3-sa-name)
  description = "S3 access test policy"
  policy      = templatefile("aws/iam/policy/s3.tpl",{ bucket_name = local.s3-bucket-name })
}

resource "aws_iam_role" "s3" {
   name = format("%s-%s", var.defaults.environment, local.s3-sa-name)
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
    name = local.s3-sa-name
    namespace = "default"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.s3.arn
    }
  }
}
