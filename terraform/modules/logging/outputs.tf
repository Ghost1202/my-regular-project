output "app_log_group_name" {
  value       = aws_cloudwatch_log_group.app.name
  description = "CloudWatch log group name for application logs"
}

output "nginx_log_group_name" {
  value       = aws_cloudwatch_log_group.nginx.name
  description = "CloudWatch log group name for nginx logs"
}

output "app_log_group_arn" {
  value       = aws_cloudwatch_log_group.app.arn
  description = "ARN of the application log group"
}

output "nginx_log_group_arn" {
  value       = aws_cloudwatch_log_group.nginx.arn
  description = "ARN of the nginx log group"
}
