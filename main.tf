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

  name              = local.name
  ami               = var.ami
  instance_type     = var.instance_type
  allocate_eip      = var.allocate_eip
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

variable "ami" {
  type        = string
  description = "AMI ID for the EC2 instance"
  default     = "ami-0e872aee57663ae2d"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "allocate_eip" {
  type        = bool
  description = "Whether to allocate an Elastic IP for the EC2 instance"
  default     = true
}

variable "zone_name" {
  type        = string
  description = "Public Route53 hosted zone name, for example example.com"
}

variable "fqdn" {
  type        = string
  description = "Fully qualified domain name for DNS record, for example app.example.com"
}
