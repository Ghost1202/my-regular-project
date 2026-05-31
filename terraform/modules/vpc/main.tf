terraform {
  required_version = "= 1.15.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.33.0"
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.0"

  name = var.name
  cidr = var.vpc_cidr
  azs  = var.azs

  public_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  intra_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  enable_nat_gateway = false
  single_nat_gateway = false
}