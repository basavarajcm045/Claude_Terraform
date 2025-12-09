# modules/s3/outputs.tf - S3 module outputs

#========== BUCKET INFORMATION ==========

output "bucket_id" {
  description = "S3 bucket ID/name"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}
##
output "bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.main.region
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.main.bucket_domain_name
}

#output "bucket_versioning" {
  #description = "The bucket versioning status"
  #value       = aws_s3_bucket_versioning.main.status
#}

#output "bucket_website_endpoint" {
  #description = "The bucket website endpoint"
  #value       = aws_s3_bucket.main.bucket_website_endpoint
#}

#output "bucket_website_domain" {
  #description = "The bucket website domain"
  #value       = aws_s3_bucket.main.website_domain
#} 

#output "bucket_policy_id" {
  #description = "The bucket policy ID"
  #value       = aws_s3_bucket_policy.main.id
#}

#========== ENCRYPTION ==========

output "encryption_type" {
  description = "Bucket encryption type"
  value       = var.encryption_type
}

