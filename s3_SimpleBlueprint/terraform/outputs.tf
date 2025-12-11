
#========== BUCKET INFORMATION ==========

output "bucket_id" {
  description = "S3 bucket ID/name"
  value       = module.s3_dev.bucket_id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3_dev
}
##
output "bucket_region" {
  description = "S3 bucket region"
  value       = module.s3_dev.bucket_region
}

output "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  value       = module.s3_dev.bucket_regional_domain_name
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = module.s3_dev.bucket_domain_name
}

/*output "bucket_versioning" {
  description = "The bucket versioning status"
  value       = aws_s3_bucket_versioning.main.status
}*/

/*output "bucket_website_endpoint" {
  description = "The bucket website endpoint"
  value       = aws_s3_bucket.main.bucket_website_endpoint
}*/

/*output "bucket_website_domain" {
  description = "The bucket website domain"
  value       = aws_s3_bucket.main.website_domain
} */

/*output "bucket_policy_id" {
  description = "The bucket policy ID"
  value       = aws_s3_bucket_policy.main.id
}*/

#========== VERSIONING & LOCK ==========

output "versioning_enabled" {
  description = "Whether versioning is enabled"
  value       = module.s3_dev.versioning_enabled
}

output "mfa_delete_enabled" {
  description = "Whether MFA delete is enabled"
  value       = module.s3_dev.mfa_delete_enabled
}

output "object_lock_enabled" {
  description = "Whether object lock is enabled"
  value       = module.s3_dev.object_lock_enabled
}

#========== ENCRYPTION ==========

output "encryption_type" {
  description = "Bucket encryption type"
  value       = module.s3_dev.encryption_type
}

#output "kms_key_id" {
#output "kms_key_arn" {
