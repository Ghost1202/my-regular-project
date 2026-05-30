terraform {
  required_version = "= 1.15.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.33.0"
    }
  }
}

locals {
  tags = merge(var.tags, { Name = var.name })

  managed_policies = {
    ecr        = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    cloudwatch = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name}-ec2-sg"
  description = "Allow traffic only from ALB"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    description     = "App port from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    description = "HTTPS to internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP to internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 9.0"

  name = var.name

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = var.subnet_ids

  traffic_source_attachments = {
    app = {
      traffic_source_identifier = var.target_group_arn
      traffic_source_type       = "elbv2"
    }
  }

  health_check_type         = "ELB"
  health_check_grace_period = 420

  launch_template_name        = var.name
  launch_template_description = "Launch template for ${var.name}"
  image_id                    = var.ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  user_data                   = var.user_data

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  network_interfaces = [{
    associate_public_ip_address = true
    security_groups             = [aws_security_group.this.id]
  }]

  create_iam_instance_profile = true
  iam_role_name               = "${var.name}-ec2-role"
  iam_role_description        = "EC2 role for ${var.name}"
  iam_role_policies           = local.managed_policies

  scaling_policies = {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = var.cpu_target_utilization
      }
    }
  }

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each   = toset(var.policy_arns)
  role       = module.asg.iam_role_name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "logs" {
  name = "${var.name}-logs-write"
  role = module.asg.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          for arn in var.cloudwatch_log_group_arns : "${arn}:*"
        ]
      }
    ]
  })
}