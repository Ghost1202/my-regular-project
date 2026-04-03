locals {
  project = "myapp"
  env     = terraform.workspace
  name    = "${local.project}-${local.env}"

  aws_region = "eu-central-1"

  zone_name = "kbnby.online"
  fqdn      = "app.kbnby.online"

  key_name          = "my-new-key"
  ssh_allowed_cidrs = ["0.0.0.0/32"]

  ami           = "ami-0e872aee57663ae2d"
  instance_type = "t3.micro"
  allocate_eip  = true

  vpc_cidr = "10.0.0.0/16"

  backup_bucket_name = "myapp-default-db-backups"
  backup_prefix      = "backups/"

  db_name     = "app"
  db_user     = "app"
  db_password = "change-me"
  db_host     = "127.0.0.1"
  db_port     = 5432

  user_data = templatefile("${path.root}/assets/userdata.tpl", {
    fqdn               = local.fqdn
    db_name            = local.db_name
    db_user            = local.db_user
    db_password        = local.db_password
    db_host            = local.db_host
    db_port            = local.db_port
    backup_bucket_name = local.backup_bucket_name
    backup_prefix      = local.backup_prefix
    aws_region         = local.aws_region
  })
}

module "vpc" {
  source = "./modules/vpc"

  name     = local.name
  vpc_cidr = local.vpc_cidr
}

module "s3" {
  source = "./modules/s3"

  name        = local.name
  bucket_name = local.backup_bucket_name
  prefix      = local.backup_prefix
}

module "app_ec2" {
  source = "./modules/ec2"

  name              = local.name
  ami               = local.ami
  instance_type     = local.instance_type
  allocate_eip      = local.allocate_eip
  key_name          = local.key_name
  subnet_id         = module.vpc.public_subnet_ids[0]
  vpc_id            = module.vpc.vpc_id
  ssh_allowed_cidrs = local.ssh_allowed_cidrs
  user_data         = local.user_data
  policy_arn        = module.s3.policy_arn
}

data "aws_route53_zone" "main" {
  name         = local.zone_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.fqdn
  type    = "A"
  ttl     = 300
  records = [module.app_ec2.public_ip]
}
