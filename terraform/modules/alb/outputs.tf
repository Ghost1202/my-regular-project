output "dns_name" {
  value       = module.alb.dns_name
  description = "DNS name of the ALB"
}

output "zone_id" {
  value       = module.alb.zone_id
  description = "Zone ID of the ALB for Route53 alias record"
}

output "security_group_id" {
  value       = module.alb.security_group_id
  description = "Security group ID of the ALB"
}

output "target_group_arn" {
  value       = module.alb.target_groups["app"].arn
  description = "ARN of the ALB target group"
}