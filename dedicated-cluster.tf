# resource "confluent_kafka_cluster" "dedicated" {
#   display_name = "dedicated_kafka_cluster"
#   availability = "MULTI_ZONE"
#   cloud        = "AWS"
#   region       = "ap-south-1"
#   dedicated {
#     cku = 2
#   }

#   network {
#     id = confluent_network.aws-private-link.id
#   }

#   environment {
#     id = data.confluent_environment.shiv-env.id
#   }

#   lifecycle {
#     prevent_destroy = false
#   }
# }

# resource "confluent_api_key" "shiv-dedicated-kafka-api-key" {
#   display_name = "shiv-dedicated-kafka-api-key"
#   description  = "Kafka API Key that is owned by 'shiv' user account"
  
#   owner {
#     id          = confluent_service_account.basic-shiva-sa.id
#     api_version = confluent_service_account.basic-shiva-sa.api_version
#     kind        = confluent_service_account.basic-shiva-sa.kind    
#   }

#   managed_resource {
#     id          = confluent_kafka_cluster.dedicated.id
#     api_version = confluent_kafka_cluster.dedicated.api_version
#     kind        = confluent_kafka_cluster.dedicated.kind

#     environment {
#       id = data.confluent_environment.shiv-env.id
#     }
#   }

#   lifecycle {
#     prevent_destroy = false
#   }
# }