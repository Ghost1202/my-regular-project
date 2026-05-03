output "dns_name" {
  value       = aws_lb.this.dns_name
  description = "DNS name of the ALB"
}

output "zone_id" {
  value       = aws_lb.this.zone_id
  description = "Zone ID of the ALB for Route53 alias record"
}

output "security_group_id" {
  value       = aws_security_group.this.id
  description = "Security group ID of the ALB"
}

output "target_group_arn" {
  value       = aws_lb_target_group.this.arn
  description = "ARN of the ALB target group"
}