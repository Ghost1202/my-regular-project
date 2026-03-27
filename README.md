# TeraAws

Terraform infrastructure for Task 3.2.4.

## What it creates

- VPC with public subnets
- Internet Gateway and public routing
- Security group for EC2
- IAM role and instance profile for EC2
- EC2 instance with optional Elastic IP
- Route53 A record pointing to the instance public IP

## Project structure

- `main.tf` — root resources and module wiring
- `providers.tf` — Terraform and provider configuration
- `variables.tf` — root input variables
- `outputs.tf` — root outputs
- `modules/vpc` — reusable VPC module
- `modules/ec2` — reusable EC2 module
- `assets/userdata.tpl` — EC2 user data template

## Notes

- Route53 record is managed in the root module.
- Terraform state should be stored remotely in S3 for team-safe usage.
