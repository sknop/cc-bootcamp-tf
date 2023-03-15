# resource "confluent_service_account" "app-producer" {
#   display_name = "app-producer"
#   description  = "Service account to produce to 'orders' topic of 'inventory' Kafka cluster"
# }

# resource "confluent_api_key" "app-producer-kafka-api-key" {
#   display_name = "app-producer-kafka-api-key"
#   description  = "Kafka API Key that is owned by 'app-producer' service account"
#   owner {
#     id          = confluent_service_account.app-producer.id
#     api_version = confluent_service_account.app-producer.api_version
#     kind        = confluent_service_account.app-producer.kind
#   }

#   managed_resource {
#     id          = confluent_kafka_cluster.basic.id
#     api_version = confluent_kafka_cluster.basic.api_version
#     kind        = confluent_kafka_cluster.basic.kind

#     environment {
#       id = data.confluent_environment.shiv-env.id
#     }
#   }
# }


# resource "confluent_kafka_acl" "app-connector-describe-on-cluster" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.basic.id
#   }
#   resource_type = "CLUSTER"
#   resource_name = "kafka-cluster"
#   pattern_type  = "LITERAL"
#   principal     = "User:${confluent_service_account.app-connector.id}"
#   host          = "*"
#   operation     = "DESCRIBE"
#   permission    = "ALLOW"
#   rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
#   credentials {
#     key    = confluent_api_key.app-manager-kafka-api-key.id
#     secret = confluent_api_key.app-manager-kafka-api-key.secret
#   }
# }

# resource "confluent_kafka_acl" "app-connector-write-on-prefix-topics" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.basic.id
#   }
#   resource_type = "TOPIC"
#   resource_name = local.database_server_name
#   pattern_type  = "PREFIXED"
#   principal     = "User:${confluent_service_account.app-connector.id}"
#   host          = "*"
#   operation     = "WRITE"
#   permission    = "ALLOW"
#   rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
#   credentials {
#     key    = confluent_api_key.app-manager-kafka-api-key.id
#     secret = confluent_api_key.app-manager-kafka-api-key.secret
#   }
# }

# resource "confluent_kafka_acl" "app-connector-create-on-prefix-topics" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.basic.id
#   }
#   resource_type = "TOPIC"
#   resource_name = local.database_server_name
#   pattern_type  = "PREFIXED"
#   principal     = "User:${confluent_service_account.app-connector.id}"
#   host          = "*"
#   operation     = "CREATE"
#   permission    = "ALLOW"
#   rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
#   credentials {
#     key    = confluent_api_key.app-manager-kafka-api-key.id
#     secret = confluent_api_key.app-manager-kafka-api-key.secret
#   }
# }
