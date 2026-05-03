resource "random_password" "this" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "this" {
  name = "${var.name}-auth"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    password = random_password.this.result
  })
}

resource "aws_secretsmanager_secret" "discord" {
  name = "${var.name}-discord-webhook"

  tags = {
    Name = var.name
  }
}

resource "aws_secretsmanager_secret_version" "discord" {
  secret_id = aws_secretsmanager_secret.discord.id
  secret_string = jsonencode({
    webhook_url = var.discord_webhook_url
  })
}