output "primary_endpoint_address" {
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
  description = "Primary endpoint address for Redis"
}

output "port" {
  value       = aws_elasticache_replication_group.this.port
  description = "Redis port"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "Security group ID of Redis"
}

output "replication_group_id" {
  value       = aws_elasticache_replication_group.this.id
  description = "ElastiCache replication group ID"
}