variable "name" {
  type        = string
  description = "Name prefix for ElastiCache resources"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Redis security group will be created"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for ElastiCache subnet group"
}

variable "allowed_sg_ids" {
  type        = list(string)
  description = "Security groups allowed to connect to Redis"
}

variable "auth_token" {
  type        = string
  description = "Redis AUTH token"
  sensitive   = true
}

variable "node_type" {
  type        = string
  description = "ElastiCache node type"
  default     = "cache.t3.micro"
}