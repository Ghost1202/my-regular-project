data "aws_region" "this" {}
data "aws_availability_zones" "available" {}

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/canonical/ubuntu/server/22.04/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

locals {
  project = "app"
  env     = terraform.workspace
  name    = "${local.project}-${local.env}"

  base_config = {
    zone_name         = "kbnby.online"
    fqdn              = "app.kbnby.online"
    key_name          = "my-regular-project-dev"
    ssh_allowed_cidrs = ["0.0.0.0/0"]
    ecr_registry      = "703288805108.dkr.ecr.eu-central-1.amazonaws.com"
  }

  envs = {
    default = {}
    dev     = {}
  }

  current_env_config = merge(
    local.base_config,
    lookup(local.envs, local.env, local.envs.default)
  )

  vpc_cidr = "10.0.0.0/16"

  user_data = base64encode(templatefile("${path.root}/assets/userdata.tpl", {
    fqdn                 = local.current_env_config.fqdn
    redis_host           = module.elasticache.primary_endpoint_address
    redis_port           = module.elasticache.port
    redis_auth_token     = module.auth.password
    app_log_group_name   = aws_cloudwatch_log_group.app.name
    nginx_log_group_name = aws_cloudwatch_log_group.nginx.name
    aws_region           = data.aws_region.this.region
    ecr_registry         = local.current_env_config.ecr_registry
  }))
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${local.name}/app"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/${local.name}/nginx"
  retention_in_days = 7
}

module "auth" {
  source = "./modules/auth"
  name   = local.name
}

module "vpc" {
  source   = "./modules/vpc"
  name     = local.name
  vpc_cidr = local.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "s3" {
  source      = "./modules/s3"
  name        = local.name
  bucket_name = "${local.name}-db-backups"
  prefix      = "db-backups/"
}

module "acm" {
  source  = "./modules/acm"
  domain  = local.current_env_config.fqdn
  zone_id = data.aws_route53_zone.main.zone_id
}

module "alb" {
  source          = "./modules/alb"
  name            = local.name
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.public_subnet_ids
  certificate_arn = module.acm.certificate_arn
}

module "asg" {
  source = "./modules/asg"

  name                  = local.name
  ami                   = data.aws_ssm_parameter.ami.value
  key_name              = local.current_env_config.key_name
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  target_group_arn      = module.alb.target_group_arn
  user_data             = local.user_data

  policy_arns = [module.s3.policy_arn]

  cloudwatch_log_group_arns = [
    aws_cloudwatch_log_group.app.arn,
    aws_cloudwatch_log_group.nginx.arn
  ]
}

module "elasticache" {
  source         = "./modules/elasticache"
  name           = local.name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnet_ids
  allowed_sg_ids = [module.asg.security_group_id]
}

data "aws_secretsmanager_secret" "discord" {
  name = "${local.name}-discord-webhook"
}

module "alerting" {
  source = "./modules/alerting"

  name                       = local.name
  autoscaling_group_name     = module.asg.autoscaling_group_name
  discord_webhook_secret_arn = data.aws_secretsmanager_secret.discord.arn
}

data "aws_route53_zone" "main" {
  name         = local.current_env_config.zone_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.current_env_config.fqdn
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}