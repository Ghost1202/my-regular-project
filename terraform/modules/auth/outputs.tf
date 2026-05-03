output "secret_arn" {
  value       = aws_secretsmanager_secret.this.arn
  description = "ARN of the auth secret"
}

output "password" {
  value       = random_password.this.result
  sensitive   = true
  description = "Generated password"
}

output "discord_webhook_secret_arn" {
  value       = aws_secretsmanager_secret.discord.arn
  description = "ARN of the Discord webhook secret"
}