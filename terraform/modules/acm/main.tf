locals {
  tags = merge(var.tags, { Name = var.domain })
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  domain_name = var.domain
  zone_id     = var.zone_id

  validation_method   = "DNS"
  wait_for_validation = true

  tags = local.tags
}