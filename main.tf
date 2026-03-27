locals {
  project = "myapp"
  env     = terraform.workspace
  name    = "${local.project}-${local.env}"

  user_data = templatefile("${path.root}/assets/userdata.tpl", {
    fqdn = var.fqdn
  })
}

module "vpc" {
  source = "./modules/vpc"
  name   = local.name
}

module "app_ec2" {
  source = "./modules/ec2"
  name   = local.name

  ami_override           = var.ec2_ami_override
  instance_type_override = var.ec2_instance_type_override
  allocate_eip_override  = var.ec2_allocate_eip_override

  key_name          = var.key_name
  subnet_id         = module.vpc.public_subnet_ids[0]
  vpc_id            = module.vpc.vpc_id
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
  user_data         = local.user_data
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

variable "ssh_allowed_cidrs" {
  type        = list(string)
  description = "List of CIDRs allowed to SSH into the EC2 instance"
}

variable "key_name" {
  type        = string
  description = "Key pair name for EC2"
}

variable "ec2_ami_override" {
  type        = string
  description = "Optional override for the AMI ID used by the EC2 module"
  default     = null
}

variable "ec2_instance_type_override" {
  type        = string
  description = "Optional override for the EC2 instance type used by the EC2 module"
  default     = null
}

variable "ec2_allocate_eip_override" {
  type        = bool
  description = "Optional override for whether the EC2 module should allocate an Elastic IP"
  default     = null
}

variable "zone_name" {
  type        = string
  description = "Public Route53 hosted zone name, for example example.com"
}

variable "fqdn" {
  type        = string
  description = "Fully qualified domain name for DNS record, for example app.example.com"
}
