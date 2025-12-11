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
  value       = var.enable_versioning
}

output "mfa_delete_enabled" {
  description = "Whether MFA delete is enabled"
  value       = var.enable_mfa_delete
}

output "object_lock_enabled" {
  description = "Whether object lock is enabled"
  value       = var.enable_object_lock
}

#========== ENCRYPTION ==========

output "encryption_type" {
  description = "Bucket encryption type"
  value       = var.encryption_type
}

#output "kms_key_id" {
#output "kms_key_arn" {
  
#========== SECURITY ==========

output "public_access_blocked" {
  description = "Whether public access is blocked"
  value       = {
    block_public_acls       = var.block_public_acls
    block_public_policy     = var.block_public_policy
    ignore_public_acls      = var.ignore_public_acls
    restrict_public_buckets = var.restrict_public_buckets
  }
}

output "ssl_enforced" {
  description = "Whether SSL/TLS is enforced"
  value       = var.enforce_ssl
}

#========== LIFECYCLE CONFIGURATION ==========

output "lifecycle_rules_count" {
  description = "Number of lifecycle rules configured"
  value       = length(var.lifecycle_rules)
}

output "lifecycle_rules_summary" {
  description = "Summary of lifecycle rules"
  value = [
    for rule in var.lifecycle_rules : {
      id      = rule.id
      enabled = rule.enabled
      prefix  = try(rule.prefix, "")
    }
  ]
}
#========== TAGS ==========
output "bucket_tags" {
  description = "Tags assigned to the S3 bucket"
  value       = aws_s3_bucket.main.tags
}
