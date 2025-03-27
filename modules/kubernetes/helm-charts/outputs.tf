output "mongodb_service_name" {
  description = "The name of the MongoDB service"
  value       = var.mongodb_enabled ? "${helm_release.mongodb[0].name}-mongodb" : null
}

output "mongodb_connection_string" {
  description = "MongoDB connection string (without credentials)"
  value       = var.mongodb_enabled ? "mongodb://${helm_release.mongodb[0].name}-mongodb.${var.mongodb_namespace}.svc.cluster.local:27017" : null
}

output "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers connection string"
  value       = var.kafka_enabled ? "${helm_release.kafka[0].name}-kafka.${var.kafka_namespace}.svc.cluster.local:9092" : null
}

output "zookeeper_connect_string" {
  description = "Zookeeper connection string"
  value       = var.kafka_enabled ? "${helm_release.kafka[0].name}-zookeeper.${var.kafka_namespace}.svc.cluster.local:2181" : null
}