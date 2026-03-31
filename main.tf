module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${local.name}-vpc"
  cidr = local.current_env_config.vpc_cidr

  azs            = local.current_env_config.azs
  public_subnets = local.current_env_config.public_subnets

  enable_nat_gateway = false
  single_nat_gateway = false

  tags = {
    Name        = "${local.name}-vpc"
    Environment = local.env
    Project     = local.project
  }
}

module "s3_backup" {
  source = "./modules/s3"

  name        = local.name
  bucket_name = local.current_env_config.backup_bucket_name
  prefix      = local.current_env_config.backup_prefix
}

module "app_ec2" {
  source = "./modules/ec2"

  name = local.name

  ami_override           = local.current_env_config.ec2_ami_override
  instance_type_override = local.current_env_config.ec2_instance_type_override
  allocate_eip_override  = local.current_env_config.ec2_allocate_eip_override

  key_name          = local.current_env_config.key_name
  subnet_id         = module.vpc.public_subnets[0]
  vpc_id            = module.vpc.vpc_id
  ssh_allowed_cidrs = local.current_env_config.ssh_allowed_cidrs
  user_data         = local.user_data
  policy_arn        = module.s3_backup.policy_arn
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
  records = [module.app_ec2.public_ip]
}
