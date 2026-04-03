output "ec2_id" {
  value       = module.app_ec2.id
  description = "ID of EC2 instance"
}

output "ec2_public_ip" {
  value       = module.app_ec2.public_ip
  description = "Public IP of EC2 instance"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "IDs of public subnets"
}
