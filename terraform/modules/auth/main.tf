resource "random_password" "this" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "this" {
  name = "${terraform.workspace}-auth"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  secret_string = jsonencode({
    password = random_password.this.result
  })
}

output "secret_arn" {
  value = aws_secretsmanager_secret.this.arn
}

output "password" {
  value     = random_password.this.result
  sensitive = true
}