output "sns_topic_arn" {
  value       = aws_sns_topic.this.arn
  description = "ARN of the SNS topic for alerts"
}