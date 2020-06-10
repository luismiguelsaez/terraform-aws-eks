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