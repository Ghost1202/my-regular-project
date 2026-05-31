output "certificate_arn" {
  value       = module.acm.acm_certificate_arn
  description = "ARN of the validated ACM certificate"
}