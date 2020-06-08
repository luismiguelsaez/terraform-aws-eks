resource "helm_release" "test" {
  name         = "test"
  chart        = "./helm/charts/test"
  force_update = true

  set {
    type  = "string"
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.s3.arn
  }

  set {
    type  = "string"
    name  = "serviceAccount.name"
    value = local.s3-sa-name
  }
}