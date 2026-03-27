terraform {
  required_version = "= 1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {}
}

locals {
  project = "myapp"
  env     = terraform.workspace
  name    = "${local.project}-${local.env}"

  base = {
    aws_region        = "eu-central-1"
    zone_name         = "kbnby.online"
    fqdn              = "app.kbnby.online"
    key_name          = "my-new-key"
    ssh_allowed_cidrs = ["0.0.0.0/32"]

    db_name     = "app"
    db_user     = "app"
    db_password = "change-me"
    db_host     = "127.0.0.1"
    db_port     = 5432

    vpc_cidr           = "10.0.0.0/16"
    azs                = ["eu-central-1a", "eu-central-1b"]
    public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
    backup_bucket_name = "myapp-default-db-backups"
    backup_prefix      = "backups/"
  }

  envs = {
    dev   = {}
    stage = {}
    main  = {}
  }

  current_env_config = merge(local.base, lookup(local.envs, local.env, local.envs["dev"]))

  user_data = templatefile("${path.root}/assets/userdata.tpl", {
    fqdn               = local.current_env_config.fqdn
    db_name            = local.current_env_config.db_name
    db_user            = local.current_env_config.db_user
    db_password        = local.current_env_config.db_password
    db_host            = local.current_env_config.db_host
    db_port            = local.current_env_config.db_port
    backup_bucket_name = local.current_env_config.backup_bucket_name
    aws_region         = local.current_env_config.aws_region
  })
}

provider "aws" {
  region = local.current_env_config.aws_region
}

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

resource "aws_s3_bucket" "backups" {
  bucket = local.current_env_config.backup_bucket_name

  tags = {
    Name        = local.current_env_config.backup_bucket_name
    Environment = local.env
    Project     = local.project
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket = aws_s3_bucket.backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "backup-retention"
    status = "Enabled"

    filter {
      prefix = local.current_env_config.backup_prefix
    }

    transition {
      days          = 7
      storage_class = "GLACIER"
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_iam_policy" "db_backup_to_s3" {
  name = "${local.name}-db-backup-to-s3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPutBackups"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = "${aws_s3_bucket.backups.arn}/${local.current_env_config.backup_prefix}*"
      },
      {
        Sid    = "AllowListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.backups.arn
      }
    ]
  })
}

module "app_ec2" {
  source = "./modules/ec2"

  name              = local.name
  key_name          = local.current_env_config.key_name
  subnet_id         = module.vpc.public_subnets[0]
  vpc_id            = module.vpc.vpc_id
  ssh_allowed_cidrs = local.current_env_config.ssh_allowed_cidrs
  user_data         = local.user_data
  policy_arn        = aws_iam_policy.db_backup_to_s3.arn
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
