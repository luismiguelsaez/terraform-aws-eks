
resource "aws_iam_role" "kubectl" {
  name = format("%s-kubectl", var.defaults.environment)

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    Name = format("%s-kubectl", var.defaults.environment)
    environment = var.defaults.environment
  }
}

resource "kubernetes_role" "kubectl" {
  metadata {
    name = "admin-access"
    namespace = "default"
    labels = {
      type = "admin"
    }
  }

  rule {
    api_groups     = ["","apps","batch","extensions"]
    resources      = ["configmaps","cronjonbs","deployments","events","ingresses","jobs","pods","pods/attach","pods/exec","pods/log","pods/portforward","secrets","services"]
    verbs          = ["create","delete","describe","get", "list", "watch","patch","update"]
  }
}

resource "kubernetes_role_binding" "kubectl" {
  metadata {
    name      = "admin-access"
    namespace = "default"
  }

  role_ref {
    kind      = "Role"
    name      = kubernetes_role.kubectl.name
    api_group = "rbac.authorization.k8s.io"
  }

  subject {
    kind      = "User"
    name      = "kubectl"
    api_group = "rbac.authorization.k8s.io"
  }
}