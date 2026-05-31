variable "name" {
  type        = string
  description = "Name prefix for alerting resources"
}

variable "autoscaling_group_name" {
  type        = string
  description = "Name of the ASG to monitor"
}

variable "discord_webhook_secret_arn" {
  type        = string
  description = "ARN of Secrets Manager secret containing Discord webhook URL"
}