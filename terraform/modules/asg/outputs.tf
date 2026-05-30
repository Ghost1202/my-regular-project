output "security_group_id" {
  value = aws_security_group.this.id
}

output "autoscaling_group_name" {
  value = module.asg.autoscaling_group_name
}