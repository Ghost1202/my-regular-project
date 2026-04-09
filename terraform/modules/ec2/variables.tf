variable "name" {
  type        = string
  description = "Name prefix for EC2-related resources"
}

variable "ami" {
  type        = string
  description = "AMI ID of the EC2 instance"
  default     = "ami-0e872aee57663ae2d"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
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


variable "policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the EC2 role"
  default     = []
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

variable "policy_arn" {
  type        = string
  description = "Policy for buckup"
}