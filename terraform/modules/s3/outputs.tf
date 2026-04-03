output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Backup bucket name"
}

output "policy_arn" {
  value       = aws_iam_policy.this.arn
  description = "IAM policy ARN for EC2 backup uploads"
}