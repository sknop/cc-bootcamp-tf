# resource "confluent_kafka_topic" "orders" {
#   kafka_cluster {
#     id = confluent_kafka_cluster.basic.id
#   }
#   topic_name         = "orders-01"
#   rest_endpoint      = confluent_kafka_cluster.basic.rest_endpoint

#   credentials {
#     key    = confluent_api_key.shiv-basic-kafka-api-key.id
#     secret = confluent_api_key.shiv-basic-kafka-api-key.secret
#   }

#   lifecycle {
#     prevent_destroy = true
#   }
# }