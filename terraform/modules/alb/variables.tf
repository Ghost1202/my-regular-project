variable "name" {
  type        = string
  description = "Name prefix for ALB-related resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for ALB"
}

variable "certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS listener"
}

variable "health_check_path" {
  type        = string
  description = "Path for ALB health checks"
  default     = "/api/status"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to all resources"
  default     = {}
}