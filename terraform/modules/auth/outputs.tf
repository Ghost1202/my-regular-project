output "secret_arn" {
  value       = aws_secretsmanager_secret.this.arn
  description = "ARN of the Secrets Manager secret"
}

output "password" {
  value       = random_password.this.result
  sensitive   = true
  description = "Generated password"
}