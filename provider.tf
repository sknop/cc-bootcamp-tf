# Configure the Confluent Provider
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.35.0"
    }
  }
}

# Option #1: Manage multiple clusters in the same Terraform workspace
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key    # optionally use CONFLUENT_CLOUD_API_KEY env var
  cloud_api_secret = var.confluent_cloud_api_secret # optionally use CONFLUENT_CLOUD_API_SECRET env var
}

provider "aws" {
  region     = var.region
  access_key = "AKIA4CEZVBNWQZ6SNH7D"
  secret_key = "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"
}