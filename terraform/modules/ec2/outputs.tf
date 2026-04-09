output "id" {
  value       = aws_instance.this.id
  description = "ID of EC2 instance"
}


output "security_group_ids" {
  value       = [aws_security_group.this.id]
  description = "Security group IDs attached to the EC2 instance"
}