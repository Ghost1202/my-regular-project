output "secret_arn" {
  value       = aws_secretsmanager_secret.this.arn
  description = "ARN of the auth secret"
}

output "password" {
  value       = random_password.this.result
  sensitive   = true
  description = "Generated password"
}