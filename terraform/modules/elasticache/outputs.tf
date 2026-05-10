output "primary_endpoint_address" {
  value       = aws_elasticache_cluster.this.cache_nodes[0].address
  description = "Primary endpoint address of the Redis cluster"
}

output "port" {
  value       = aws_elasticache_cluster.this.port
  description = "Port of the Redis cluster"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "Security group ID attached to the Redis cluster"
}
}
