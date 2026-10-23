output "state_bucket_name" {
  description = "Name of the S3 bucket that stores the Terraform state"
  value       = aws_s3_bucket.state.bucket
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket that stores the Terraform state"
  value       = aws_s3_bucket.state.arn
}
