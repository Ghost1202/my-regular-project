resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.name}/app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/${var.name}/nginx"
  retention_in_days = 7
}
