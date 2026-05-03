output "security_group_id" {
  value       = aws_security_group.this.id
  description = "Security group ID of EC2 instances in ASG"
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.this.name
  description = "Name of the Auto Scaling Group"
}