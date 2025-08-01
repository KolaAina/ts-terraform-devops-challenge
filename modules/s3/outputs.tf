output "bucket_name" {
  value       = aws_s3_bucket.this.bucket
  description = "Created S3 bucket name"
}

output "bucket_arn" {
  value       = aws_s3_bucket.this.arn
  description = "Created S3 bucket ARN"
}

output "oidc_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM Role ARN for GitHub OIDC"
}
