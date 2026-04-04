locals {
  project = "app"
  env     = terraform.workspace
  name    = "${local.project}-${local.env}"

  base_config = {
    aws_region = "eu-central-1"
    zone_name  = "kbnby.online"
    fqdn       = "app.kbnby.online"

    key_name = "my-regular-project-dev"

    ssh_allowed_cidrs = [
      "0.0.0.0/0"
    ]

    ami              = "ami-0e872aee57663ae2d"
    instance_type    = "t3.micro"
    allocate_eip     = true
    elasticache_type = "cache.t3.micro"
  }

  envs = {
    default = {}
    dev     = {}
  }

  current_env_config = merge(
    local.base_config,
    lookup(local.envs, local.env, local.envs.default)
  )

  user_data = templatefile("${path.module}/assets/userdata.tpl", {
    fqdn                 = local.current_env_config.fqdn
    redis_host           = module.elasticache.primary_endpoint_address
    redis_port           = module.elasticache.port
    redis_auth_token     = var.redis_auth_token
    app_log_group_name   = aws_cloudwatch_log_group.app.name
    nginx_log_group_name = aws_cloudwatch_log_group.nginx.name
  })
}

module "vpc" {
  source = "./modules/vpc"
  name   = local.name
}

module "ec2" {
  source = "./modules/ec2"

  name                   = local.name
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_id                 = module.vpc.vpc_id
  key_name               = local.current_env_config.key_name
  ssh_allowed_cidrs      = local.current_env_config.ssh_allowed_cidrs
  user_data              = local.user_data
  ami_override           = local.current_env_config.ami
  instance_type_override = local.current_env_config.instance_type
  allocate_eip_override  = local.current_env_config.allocate_eip

  cloudwatch_log_group_arns = [
    aws_cloudwatch_log_group.app.arn,
    aws_cloudwatch_log_group.nginx.arn
  ]
}

module "elasticache" {
  source = "./modules/elasticache"

  name           = local.name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids
  allowed_sg_ids = [module.ec2.security_group_id]
  auth_token     = var.redis_auth_token
  node_type      = local.current_env_config.elasticache_type
}

data "aws_route53_zone" "main" {
  name         = local.current_env_config.zone_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.current_env_config.fqdn
  type    = "A"
  ttl     = 300
  records = [module.ec2.public_ip]
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${local.name}/app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/${local.name}/nginx"
  retention_in_days = 7
}

variable "redis_auth_token" {
  type        = string
  description = "Redis AUTH token for ElastiCache"
  sensitive   = true
}