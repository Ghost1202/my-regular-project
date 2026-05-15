locals {
  tags = {
    Name = var.name
  }
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = var.name
  load_balancer_type = "application"
  internal           = false

  vpc_id  = var.vpc_id
  subnets = var.subnet_ids

  drop_invalid_header_fields = true

  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    https = {
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = var.certificate_arn

      forward = {
        target_group_key = "app"
      }
    }
  }

  target_groups = {
    app = {
      name              = var.name
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      create_attachment = false

      health_check = {
        path                = var.health_check_path
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
    }
  }

  tags = local.tags
}