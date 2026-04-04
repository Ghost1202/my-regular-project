variable "name" {
  type        = string
  description = "Name prefix for EC2-related resources"
}

variable "ami_override" {
  type        = string
  description = "Optional override for the AMI ID of the EC2 instance"
  default     = null
}

variable "instance_type_override" {
  type        = string
  description = "Optional override for the EC2 instance type"
  default     = null
}

variable "key_name" {
  type        = string
  description = "Name of the SSH key pair to use"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where EC2 will be launched"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EC2 security group will be created"
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  description = "Allowed CIDRs for SSH access"
}

variable "allocate_eip_override" {
  type        = bool
  description = "Optional override for whether to allocate an Elastic IP"
  default     = null
}

variable "user_data" {
  type        = string
  description = "Rendered user data script for the EC2 instance"
}

variable "cloudwatch_log_group_arns" {
  type        = list(string)
  description = "List of CloudWatch log group ARNs for least-privilege writes"
  default     = []
}