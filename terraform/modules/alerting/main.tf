data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda.py"
  output_path = "${path.module}/.build/lambda.zip"
}

module "sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = "~> 6.0"

  name              = var.name
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = var.name
  }
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 8.0"

  function_name = var.name
  handler       = "lambda.handler"
  runtime       = "python3.12"

  create_package         = false
  local_existing_package = data.archive_file.lambda.output_path

  environment_variables = {
    DISCORD_WEBHOOK_SECRET_ARN = var.discord_webhook_secret_arn
  }

  attach_policy_json = true
  policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.discord_webhook_secret_arn
      }
    ]
  })

  allowed_triggers = {
    sns = {
      principal  = "sns.amazonaws.com"
      source_arn = module.sns.topic_arn
    }
  }

  tags = {
    Name = var.name
  }
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = module.sns.topic_arn
  protocol  = "lambda"
  endpoint  = module.lambda.lambda_function_arn
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "CPU utilization above 90%"

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_actions = [module.sns.topic_arn]
  ok_actions    = [module.sns.topic_arn]

  tags = {
    Name = var.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.name}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 60
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "Memory utilization above 90%"

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }

  alarm_actions = [module.sns.topic_arn]
  ok_actions    = [module.sns.topic_arn]

  tags = {
    Name = var.name
  }
}