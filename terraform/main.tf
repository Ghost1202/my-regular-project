data "aws_region" "this" {}

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
  azs      = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

  public_subnets = [for i, az in local.azs : cidrsubnet(local.vpc_cidr, 8, i)]
  intra_subnets  = [for i, az in local.azs : cidrsubnet(local.vpc_cidr, 8, i + 10)]

  user_data = templatefile("${path.root}/assets/userdata.tpl", {
    fqdn                 = local.current_env_config.fqdn
    redis_host           = module.elasticache.primary_endpoint_address
    redis_port           = module.elasticache.port
    redis_auth_token     = random_password.redis_auth.result
    app_log_group_name   = module.logging.app_log_group_name
    nginx_log_group_name = module.logging.nginx_log_group_name
    aws_region           = data.aws_region.this.region
    ecr_registry         = local.current_env_config.ecr_registry
  })
}

resource "random_password" "redis_auth" {
  length  = 32
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = local.name
  cidr = local.vpc_cidr

  azs            = local.azs
  public_subnets = local.public_subnets
  intra_subnets  = local.intra_subnets

  enable_nat_gateway = false
  single_nat_gateway = false
}

module "logging" {
  source = "./modules/logging"
  name   = local.name
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
  subnet_id         = module.vpc.public_subnets[0]
  vpc_id            = module.vpc.vpc_id
  key_name          = local.current_env_config.key_name
  ssh_allowed_cidrs = local.current_env_config.ssh_allowed_cidrs
  user_data         = local.user_data
  policy_arns       = [module.s3.policy_arn]
  policy_arn        = module.s3.policy_arn

  cloudwatch_log_group_arns = [
    module.logging.app_log_group_arn,
    module.logging.nginx_log_group_arn
  ]
}

module "elasticache" {
  source = "./modules/elasticache"

  name           = local.name
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.public_subnets
  allowed_sg_ids = module.ec2.security_group_ids
  auth_token     = random_password.redis_auth.result
}

data "aws_route53_zone" "main" {
  name         = local.current_env_config.zone_name
  private_zone = false
}
