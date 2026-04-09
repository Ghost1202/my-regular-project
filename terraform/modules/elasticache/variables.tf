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

variable "node_type" {
  type        = string
  description = "ElastiCache node type"
  default     = "cache.t4g.micro"
}

variable "engine_version" {
  type        = string
  description = "Redis engine version"
  default     = "7.1"
}
