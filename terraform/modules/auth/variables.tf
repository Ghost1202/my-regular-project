variable "name" {
  type        = string
  description = "Name prefix for auth resources"
}

variable "discord_webhook_url" {
  type        = string
  description = "Discord webhook URL to store in Secrets Manager"
  sensitive   = true
}