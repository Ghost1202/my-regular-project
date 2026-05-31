output "sns_topic_arn" {
  value       = module.sns.topic_arn
  description = "ARN of the SNS topic for alerts"
}