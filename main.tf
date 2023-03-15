data "confluent_environment" "shiv-env" {
  id = "env-r50o77"
}

resource "confluent_service_account" "basic-shiva-sa" {
  display_name = "basic-cluster-shiva-sa"
  description  = "Service Account for basic cluster of shiva"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
