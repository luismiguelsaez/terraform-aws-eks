provider "aws" {
  version = "~> 2.0"
  region  = "eu-west-1"
  profile = "default"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

provider "kubernetes" {
  host                   = "${data.aws_eks_cluster.main.endpoint}"
  cluster_ca_certificate = "${base64decode(data.aws_eks_cluster.main.certificate_authority.0.data)}"
  token                  = "${data.aws_eks_cluster_auth.main.token}"
  load_config_file       = false
}