
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

#output "bucket_versioning" {
#description = "The bucket versioning status"
#value       = module.s3_dev.bucket_versioning
#}

#output "bucket_website_endpoint" {
#description = "The bucket website endpoint"
#value       = module.s3_dev.bucket_website_endpoint
#}

#output "bucket_website_domain" {
#description = "The bucket website domain"
#value       = module.s3_dev.bucket_website_domain
#}

#output "bucket_policy_id" {
#description = "The bucket policy ID"
#value       = module.s3_dev.bucket_policy_id
#}