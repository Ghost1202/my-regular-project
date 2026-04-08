locals {
  project = "app"
  env     = terraform.workspace
  name    = "${local.project}-${local.env}"

  base_config = {
    aws_region        = "eu-central-1"
    zone_name         = "kbnby.online"
    fqdn              = "app.kbnby.online"
    key_name          = "my-regular-project-dev"
    ssh_allowed_cidrs = ["0.0.0.0/0"]

    vpc_cidr = "10.0.0.0/16"
    azs      = ["eu-central-1a", "eu-central-1b"]

    public_subnets = [
      "10.0.1.0/24",
      "10.0.2.0/24"
    ]

    ecr_registry = "703288805108.dkr.ecr.eu-central-1.amazonaws.com"
  }

  envs = {
    default = {}
    dev     = {}
  }

  current_env_config = merge(
    local.base_config,
    lookup(local.envs, local.env, local.envs.default)
  )

  user_data = templatefile("${path.root}/assets/userdata.tpl", {
    fqdn                 = local.current_env_config.fqdn
    redis_host           = module.elasticache.primary_endpoint_address
    redis_port           = module.elasticache.port
    redis_auth_token     = random_password.redis_auth.result
    app_log_group_name   = module.logging.app_log_group_name
    nginx_log_group_name = module.logging.nginx_log_group_name
    aws_region           = local.current_env_config.aws_region
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
  cidr = local.current_env_config.vpc_cidr

  azs            = local.current_env_config.azs
  public_subnets = local.current_env_config.public_subnets

  enable_nat_gateway = false
  single_nat_gateway = false

  tags = {
    Name        = local.name
    Environment = local.env
    Project     = local.project
  }
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

# --- Новая Security Group для EC2 с открытым портом 8080 ---
resource "aws_security_group" "ec2_sg" {
  name        = local.name
  description = "EC2 security group with SSH and HTTP 8080 open"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.current_env_config.ssh_allowed_cidrs
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ec2" {
  source = "./modules/ec2"

  name              = local.name
  subnet_id         = module.vpc.public_subnets[0]
  vpc_id            = module.vpc.vpc_id
  key_name          = local.current_env_config.key_name
  ssh_allowed_cidrs = local.current_env_config.ssh_allowed_cidrs
  user_data         = local.user_data
  backup_policy_arn = module.s3.policy_arn

  security_group_ids = [aws_security_group.ec2_sg.id]

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

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.current_env_config.fqdn
  type    = "A"
  ttl     = 300
  records = [module.ec2.public_ip]
}
