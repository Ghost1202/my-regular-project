data "aws_region" "this" {}

data "aws_availability_zones" "available" {}

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

  user_data = templatefile("${path.root}/assets/userdata.tpl", {
    fqdn                 = local.current_env_config.fqdn
    redis_host           = module.elasticache.primary_endpoint_address
    redis_port           = module.elasticache.port
    redis_auth_token     = module.auth.password
    app_log_group_name   = aws_cloudwatch_log_group.app.name
    nginx_log_group_name = aws_cloudwatch_log_group.nginx.name
    aws_region           = data.aws_region.this.region
    ecr_registry         = local.current_env_config.ecr_registry
  })
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
  source = "./modules/vpc"

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

module "ec2" {
  source = "./modules/ec2"

  name              = local.name
  subnet_id         = module.vpc.public_subnet_ids[0]
  vpc_id            = module.vpc.vpc_id
  key_name          = local.current_env_config.key_name
  ssh_allowed_cidrs = local.current_env_config.ssh_allowed_cidrs
  user_data         = local.user_data

  policy_arns = [module.s3.policy_arn]

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
  allowed_sg_ids = module.ec2.security_group_ids
  auth_token     = module.auth.password
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