output "id" {
  value       = aws_instance.this.id
  description = "ID of EC2 instance"
}

output "public_ip" {
  value       = coalesce(try(aws_eip.this[0].public_ip, null), aws_instance.this.public_ip)
  description = "Public IP of EC2 instance"
}
