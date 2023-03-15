resource "confluent_service_account" "shiva-basic-app-manager" {
  display_name = "shiva-basic-app-manager"
  description  = "Service account to manage 'inventory' Kafka cluster"
}

resource "confluent_role_binding" "shiva-basic-app-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.shiva-basic-app-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "shiva-basic-app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.shiva-basic-app-manager.id
    api_version = confluent_service_account.shiva-basic-app-manager.api_version
    kind        = confluent_service_account.shiva-basic-app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.shiv-env.id
    }
  }

  # The goal is to ensure that confluent_role_binding.app-manager-kafka-cluster-admin is created before
  # confluent_api_key.app-manager-kafka-api-key is used to create instances of
  # confluent_kafka_topic, confluent_kafka_acl resources.

  # 'depends_on' meta-argument is specified in confluent_api_key.app-manager-kafka-api-key to avoid having
  # multiple copies of this definition in the configuration which would happen if we specify it in
  # confluent_kafka_topic, confluent_kafka_acl resources instead.
  depends_on = [
    confluent_role_binding.shiva-basic-app-manager-kafka-cluster-admin
  ]
}

resource "confluent_kafka_acl" "app-connector-write-on-prefix-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "shiva-bootcamp"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.shiva-basic-app-manager.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "app-connector-create-on-prefix-topics" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = "shiva-bootcamp"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.shiva-basic-app-manager.id}"
  host          = "*"
  operation     = "CREATE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
}

resource "confluent_connector" "source" {
  environment {
    id = data.confluent_environment.shiv-env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  config_nonsensitive = {
    "name" = "OracleShivSourceBootcamp"
    "connector.class" = "OracleCdcSource"
    "oracle.port" = 1521
    "oracle.server" = "bootcamp-oracle.ckghi8vtapgh.ap-south-2.rds.amazonaws.com"
    "oracle.sid" = "BOOTCAMP"
    "emit.tombstone.on.delete" = "true"
    "output.data.value.format" = "JSON"
    "table.inclusion.regex" = "BOOTCAMP[.]MOVIELENS[.](GENRES|MOVIES|TAGS|RATINGS|MOVIES_TO_GENRES).*"
    "tasks.max" = 1
    "kafka.auth.mode" = "KAFKA_API_KEY"
    "kafka.api.key" = "${confluent_api_key.app-manager-kafka-api-key.id}"
    "kafka.api.secret" = "${confluent_api_key.app-manager-kafka-api-key.secret}"
  }
  config_sensitive = {
    "oracle.username" = "shiv"
    "oracle.password" = "shiv-secret"
  }
}

resource "confluent_connector" "mysql-source" {
  environment {
    id = data.confluent_environment.shiv-env.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  config_nonsensitive = {
    "name" = "MySQLShivSourceBootcamp"
    "connector.class" = "MySqlCdcSource"
    "database.hostname" = "ec2-18-60-121-200.ap-south-2.compute.amazonaws.com"
    "database.port" = 3306
    "database.server.name" = "shiva-bootcamp"
    "database.ssl.mode" = "preferred"
    "output.data.format" = "JSON"
    "tasks.max" = 1
    "kafka.auth.mode" = "KAFKA_API_KEY"
    "kafka.api.key" = "${confluent_api_key.app-manager-kafka-api-key.id}"
    "kafka.api.secret" = "${confluent_api_key.app-manager-kafka-api-key.secret}"
  }
  config_sensitive = {
    "database.password" = "shiv-secret"
    "database.user" = "shiv"
  }
depends_on = [
    confluent_kafka_acl.app-connector-write-on-prefix-topics,
    confluent_kafka_acl.app-connector-create-on-prefix-topics
  ]
}

# resource "confluent_connector" "postgres-source" {
#   environment {
#     id = data.confluent_environment.shiv-env.id
#   }
#   kafka_cluster {
#     id = confluent_kafka_cluster.basic.id
#   }
#   config_nonsensitive = {
#     "name" = "PostgresShivSourceBootcamp"
#     "connector.class" = "PostgresCdcSource"
#     "database.hostname" = "ec2-18-60-124-129.ap-south-2.compute.amazonaws.com"
#     "database.dbname" = "movielens"
#     "database.port" = 5432
#     "database.server.name" = "shiva-bootcamp"
#     "database.ssl.mode" = "disable"
#     "output.data.format" = "JSON"
#     "tasks.max" = 1
#     "kafka.auth.mode" = "KAFKA_API_KEY"
#     "kafka.api.key" = "${confluent_api_key.app-manager-kafka-api-key.id}"
#     "kafka.api.secret" = "${confluent_api_key.app-manager-kafka-api-key.secret}"
#   }
#   config_sensitive = {
#     "database.password" = "shiv-secret"
#     "database.user" = "shiv"
#   }
# }

