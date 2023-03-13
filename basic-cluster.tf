resource "confluent_kafka_cluster" "basic" {
  display_name = "my-first-basic-cluster"
  availability = "SINGLE_ZONE"
  cloud        = "AWS"
  region       = "ap-south-1"
  basic {}

  environment {
    id = data.confluent_environment.shiv-env.id
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "confluent_api_key" "shiv-basic-kafka-api-key" {
  display_name = "shiv-basic-kafka-api-key"
  description  = "Kafka API Key that is owned by 'shiv' user account"
  
  owner {
    id          = confluent_service_account.basic-shiva-sa.id
    api_version = confluent_service_account.basic-shiva-sa.api_version
    kind        = confluent_service_account.basic-shiva-sa.kind    
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.shiv-env.id
    }
  }

  lifecycle {
    prevent_destroy = false
  }
}