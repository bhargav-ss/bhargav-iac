output "endpoint" {
  description = "The primary endpoint for the Tiptap Redis cluster."
  value       = aws_elasticache_replication_group.tiptap_redis.primary_endpoint_address
}

output "port" {
  description = "The port for the Tiptap Redis cluster."
  value       = aws_elasticache_replication_group.tiptap_redis.port
}