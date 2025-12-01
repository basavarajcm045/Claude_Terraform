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

output "bucket_region" {
  description = "S3 bucket region"
  value       = aws_s3_bucket.main.region
}

output "bucket_domain_name" {
  description = "S3 bucket regional domain name"
  value       = aws_s3_bucket.main.bucket_regional_domain_name
}

output "bucket_website_endpoint" {
  description = "S3 bucket website endpoint (if static hosting enabled)"
  value       = try("${aws_s3_bucket.main.id}.s3-website-${aws_s3_bucket.main.region}.amazonaws.com", "")
}

#========== LOGGING ==========

output "logging_bucket_id" {
  description = "S3 logging bucket ID"
  value       = try(aws_s3_bucket.logging[0].id, "")
}

output "logging_bucket_arn" {
  description = "S3 logging bucket ARN"
  value       = try(aws_s3_bucket.logging[0].arn, "")
}

output "log_prefix" {
  description = "Prefix for access logs"
  value       = var.enable_logging ? var.log_prefix : ""
}

#========== ENCRYPTION ==========

output "encryption_type" {
  description = "Bucket encryption type"
  value       = var.encryption_type
}

output "kms_key_id" {
  description = "KMS key ID (if using KMS encryption)"
  value       = var.encryption_type == "kms" ? (var.kms_key_id != "" ? var.kms_key_id : try(aws_kms_key.s3[0].id, "")) : null
  sensitive   = true
}

output "kms_key_arn" {
  description = "KMS key ARN (if using KMS encryption)"
  value       = var.encryption_type == "kms" ? (var.kms_key_id != "" ? "arn:aws:kms:*:*:key/${var.kms_key_id}" : try(aws_kms_key.s3[0].arn, "")) : null
  sensitive   = true
}

#========== REPLICATION ==========

output "replication_role_arn" {
  description = "IAM role ARN for replication"
  value       = try(aws_iam_role.replication[0].arn, "")
}

output "replication_enabled" {
  description = "Whether replication is enabled"
  value       = var.enable_replication
}

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

#========== FEATURES ==========

output "cors_enabled" {
  description = "Whether CORS is enabled"
  value       = var.enable_cors
}

output "logging_enabled" {
  description = "Whether access logging is enabled"
  value       = var.enable_logging
}

output "metrics_enabled" {
  description = "Whether request metrics are enabled"
  value       = var.enable_metrics
}

output "inventory_enabled" {
  description = "Whether inventory reports are enabled"
  value       = var.enable_inventory
}

output "intelligent_tiering_enabled" {
  description = "Whether intelligent tiering is enabled"
  value       = var.enable_intelligent_tiering
}

output "request_payment_enabled" {
  description = "Whether requester pays is enabled"
  value       = var.enable_request_payment
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

#========== API ENDPOINTS ==========

output "bucket_endpoint_url" {
  description = "S3 bucket endpoint URL for API access"
  value       = "https://${aws_s3_bucket.main.id}.s3.${aws_s3_bucket.main.region}.amazonaws.com"
}

output "bucket_virtual_hosted_style_url" {
  description = "Virtual-hosted style URL"
  value       = "https://${aws_s3_bucket.main.id}.s3.${aws_s3_bucket.main.region}.amazonaws.com"
}

output "bucket_path_style_url" {
  description = "Path-style URL"
  value       = "https://s3.${aws_s3_bucket.main.region}.amazonaws.com/${aws_s3_bucket.main.id}"
}

#========== MONITORING ==========

output "cloudwatch_alarms_enabled" {
  description = "Whether CloudWatch alarms are enabled"
  value       = var.enable_cloudwatch_alarms
}

output "bucket_size_alarm_name" {
  description = "CloudWatch alarm name for bucket size"
  value       = try(aws_cloudwatch_metric_alarm.bucket_size[0].alarm_name, "")
}

output "object_count_alarm_name" {
  description = "CloudWatch alarm name for object count"
  value       = try(aws_cloudwatch_metric_alarm.object_count[0].alarm_name, "")
}

#========== COMPLIANCE SUMMARY ==========

output "compliance_summary" {
  description = "Summary of compliance configurations"
  value = {
    versioning_enabled           = var.enable_versioning
    mfa_delete_enabled           = var.enable_mfa_delete
    encryption_enabled           = true
    encryption_type              = var.encryption_type
    ssl_enforced                 = var.enforce_ssl
    public_access_blocked        = var.block_public_acls && var.block_public_policy
    access_logging_enabled       = var.enable_logging
    object_lock_enabled          = var.enable_object_lock
    replication_enabled          = var.enable_replication
    lifecycle_management_enabled = length(var.lifecycle_rules) > 0
    metrics_enabled              = var.enable_metrics
    inventory_enabled            = var.enable_inventory
  }
}

#========== RESOURCE ARNS ==========

output "bucket_objects_arn" {
  description = "ARN for bucket objects"
  value       = "${aws_s3_bucket.main.arn}/*"
}

output "replication_role_policy_arn" {
  description = "Replication policy ARN"
  value       = try(aws_iam_role_policy.replication[0].arn, "")
}
