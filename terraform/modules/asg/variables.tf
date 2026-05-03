variable "name" {
  type        = string
  description = "Name prefix for ASG-related resources"
}

variable "ami" {
  type        = string
  description = "AMI ID for Launch Template"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "SSH key pair name"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for ASG"
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group ID of the ALB — EC2 only accepts traffic from it"
}

variable "target_group_arn" {
  type        = string
  description = "ARN of the ALB target group"
}

variable "user_data" {
  type        = string
  description = "Base64-encoded user data script"
}

variable "policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to EC2 role"
  default     = []
}

variable "cloudwatch_log_group_arns" {
  type        = list(string)
  description = "List of CloudWatch log group ARNs for least-privilege writes"
  default     = []
}

variable "min_size" {
  type        = number
  description = "Minimum number of EC2 instances in ASG"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of EC2 instances in ASG"
  default     = 3
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of EC2 instances in ASG"
  default     = 1
}

variable "cpu_target_utilization" {
  type        = number
  description = "Target CPU utilization percentage for scaling"
  default     = 70
}

variable "ssh_allowed_cidrs" {
  type        = list(string)
  description = "CIDRs allowed for SSH access"
  default     = ["0.0.0.0/0"]
}