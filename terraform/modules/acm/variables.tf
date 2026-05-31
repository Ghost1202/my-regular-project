variable "domain" {
  type        = string
  description = "Domain name for the certificate"
}

variable "zone_id" {
  type        = string
  description = "Route53 zone ID for DNS validation"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}