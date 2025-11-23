# modules/s3/outputs.tf

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

output "s3_bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "s3_bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.main.region
}

output "logging_bucket_name" {
  description = "S3 logging bucket name"
  value       = try(aws_s3_bucket.logging[0].id, "")
}