data "confluent_schema_registry_region" "mumbai" {
  cloud   = "AWS"
  region  = "us-east-2"
  package = "ESSENTIALS"
}

resource "confluent_schema_registry_cluster" "essentials" {
  package = data.confluent_schema_registry_region.mumbai.package

  environment {
    id = data.confluent_environment.shiv-env.id
  }

  region {
    id = data.confluent_schema_registry_region.mumbai.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_api_key" "env-shiv-schema-registry-api-key" {
  display_name = "env-shiv-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'basic-shiv-sa' service account"
  owner {
    id          = confluent_service_account.basic-shiva-sa.id
    api_version = confluent_service_account.basic-shiva-sa.api_version
    kind        = confluent_service_account.basic-shiva-sa.kind
  }

  managed_resource {
    id          = confluent_schema_registry_cluster.essentials.id
    api_version = confluent_schema_registry_cluster.essentials.api_version
    kind        = confluent_schema_registry_cluster.essentials.kind

    environment {
      id = data.confluent_environment.shiv-env.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}

