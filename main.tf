terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "myapp"
      Environment = terraform.workspace
    }
  }
}

data "aws_availability_zones" "available" {}

locals {
  project = "myapp"
  env     = terraform.workspace
  name    = "${local.project}-${local.env}"

  backup_bucket_name = "${local.name}-db-backups"

  user_data = templatefile("${path.root}/assets/userdata.tpl", {
    fqdn               = var.fqdn
    aws_region         = var.aws_region
    backup_bucket_name = local.backup_bucket_name
    db_name            = var.db_name
    db_user            = var.db_user
    db_password        = var.db_password
    db_host            = var.db_host
    db_port            = var.db_port
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = local.name
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  public_subnets = var.public_subnets

  enable_nat_gateway      = false
  enable_vpn_gateway      = false
  map_public_ip_on_launch = true

  tags = {
    Name = local.name
  }
}

module "app_ec2" {
  source = "./modules/ec2"

  name                   = local.name
  ami_override           = var.ec2_ami_override
  instance_type_override = var.ec2_instance_type_override
  allocate_eip_override  = var.ec2_allocate_eip_override
  key_name               = var.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_id                 = module.vpc.vpc_id
  ssh_allowed_cidrs      = var.ssh_allowed_cidrs
  user_data              = local.user_data
  policy_arn             = aws_iam_policy.ec2_backup_to_s3.arn
}


data "aws_route53_zone" "main" {
  name         = var.zone_name
  private_zone = false
}

resource "aws_route53_record" "this" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.fqdn
  type    = "A"
  ttl     = 300
  records = [module.app_ec2.public_ip]
}

resource "aws_s3_bucket" "db_backups" {
  bucket = local.backup_bucket_name
}

resource "aws_s3_bucket_versioning" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "db_backups" {
  bucket = aws_s3_bucket.db_backups.id

  rule {
    id     = "db-backup-retention"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    transition {
      days          = 7
      storage_class = "GLACIER"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

data "aws_iam_policy_document" "ec2_backup_to_s3" {
  statement {
    sid    = "ListBackupPrefix"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.db_backups.arn
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["backups/*"]
    }
  }

  statement {
    sid    = "WriteBackupObjects"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload"
    ]

    resources = [
      "${aws_s3_bucket.db_backups.arn}/backups/*"
    ]
  }
}

resource "aws_iam_policy" "ec2_backup_to_s3" {
  name   = "${local.name}-ec2-backup-to-s3"
  policy = data.aws_iam_policy_document.ec2_backup_to_s3.json
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = list(string)
  default = [
    "10.0.0.0/24",
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "ssh_allowed_cidrs" {
  type = list(string)
}

variable "key_name" {
  type = string
}

variable "ec2_ami_override" {
  type    = string
  default = null
}

variable "ec2_instance_type_override" {
  type    = string
  default = null
}

variable "ec2_allocate_eip_override" {
  type    = bool
  default = null
}

variable "zone_name" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_host" {
  type    = string
  default = "127.0.0.1"
}

variable "db_port" {
  type    = number
  default = 5432
}

output "ec2_id" {
  value = module.app_ec2.id
}

output "ec2_public_ip" {
  value = module.app_ec2.public_ip
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "backup_bucket_name" {
  value = aws_s3_bucket.db_backups.bucket
}
