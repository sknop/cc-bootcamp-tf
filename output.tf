output "basic_cluster_endpoint" {
  value = confluent_kafka_cluster.basic.bootstrap_endpoint
  description = "basic cluster endpoint"
}

output "basic_cluster_rest_endpoint" {
  value = confluent_kafka_cluster.basic.rest_endpoint
  description = "basic cluster rest endpoint"
}