locals {
    regional_azs = ["aps1-az1", "aps1-az3", "aps1-az2"]
}

resource "confluent_network" "aws-private-link" {
  display_name     = "AWS Private Link Network"
  cloud            = "AWS"
  region           = "ap-south-1"
  connection_types = ["PRIVATELINK"]
  zones            = local.regional_azs
  environment {
    id = data.confluent_environment.shiv-env.id
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "confluent_private_link_access" "aws" {
  display_name = "AWS Private Link Access"
  aws {
    account = var.customer_aws_account
  }
  environment {
    id = data.confluent_environment.shiv-env.id
  }
  network {
    id = confluent_network.aws-private-link.id
  }
  lifecycle {
    prevent_destroy = false
  }
}