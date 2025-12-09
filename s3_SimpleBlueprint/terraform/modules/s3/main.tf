#========== Local Variables ==========

locals {
  bucket_prefix = "${var.project_name}-${var.environment}"
  
  # Default tags
  default_tags = merge(
    var.tags,
    {
      Module      = "S3"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

#========== Random Suffix (only used when bucket_name is not provided) ==========
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

#========== S3 Bucket ==========#

resource "aws_s3_bucket" "main" {
  #bucket = var.bucket_name != "" ? var.bucket_name : "${local.bucket_prefix}-${random_string.bucket_suffix.result}"
  bucket = "${local.bucket_prefix}-${var.bucket_name}"
  force_destroy = var.force_destroy
  
  tags = merge(
    local.default_tags,
    {
      #Name = var.bucket_name != "" ? var.bucket_name : "${local.bucket_prefix}-bucket"
      #Name = var.bucket_name
      Name = "${local.bucket_prefix}-${var.bucket_name}"

    }
  )
}

#========== Bucket Versioning ==========#

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.enable_versioning && var.enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

#========== ENCRYPTION ==========

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      #sse_algorithm     = var.encryption_type
      #kms_master_key_id = var.kms_key_id != "" ? var.kms_key_id : null
      sse_algorithm      = var.encryption_type == "kms" ? "aws:kms" : "AES256"
      kms_master_key_id  = var.encryption_type == "kms" && var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}
      
#========== PUBLIC ACCESS BLOCK ==========

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

#========== LIFECYCLE CONFIGURATION ==========

resource "aws_s3_bucket_lifecycle_configuration" "main" {

  #Create this resource only if lifecycle_rules is not empty
  for_each = length(var.lifecycle_rules) > 0 ? toset([ "enabled" ]) : []

  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Filtering
      #dynamic "filter" {
        #for_each = rule.value.filters != null ? [rule.value.filters] : []
        #content {
          #and {
            #prefix = try(filter.value.prefix, "")
            #tags   = try(filter.value.tags, {})
          #}
        #}
      #}

      filter {
        prefix = rule.value.prefix
      }

      # Transitions
      dynamic "transition" {
        for_each = try(rule.value.transitions, [])
        content {
          days          = try(transition.value.days, null)
          #date          = try(transition.value.date, null)
          storage_class = transition.value.storage_class
        }
      }

      # Expiration
      dynamic "expiration" {
        for_each = try(rule.value.expiration, null) != null ? [rule.value.expiration] : []
        content {
          days                         = try(expiration.value.days, null)
          date                         = try(expiration.value.date, null)
          expired_object_delete_marker = try(expiration.value.expired_object_delete_marker, null)
        }
      }
      
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

#========== BUCKET POLICY ==========

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      # Deny unencrypted uploads
      var.enforce_encrypted_uploads ? [
        {
          Sid    = "DenyUnencryptedObjectUploads"
          Effect = "Deny"
          Principal = "*"
          Action = "s3:PutObject"
          Resource = "${aws_s3_bucket.main.arn}/*"
          Condition = {
            StringNotEquals = {
              "s3:x-amz-server-side-encryption" = var.encryption_type == "kms" ? "aws:kms" : "AES256"
            }
          }
        }
      ] : [],
      
      # Deny insecure transport (HTTP)
      var.enforce_ssl ? [
        {
          Sid    = "DenyInsecureTransport"
          Effect = "Deny"
          Principal = "*"
          Action = "s3:*"
          Resource = [
            aws_s3_bucket.main.arn,
            "${aws_s3_bucket.main.arn}/*"
          ]
          Condition = {
            Bool = {
              "aws:SecureTransport" = "false"
            }
          }
        }
      ] : [],

      # Allow specific principals if provided
      var.allow_principals != {} ? [
        for principal, permissions in var.allow_principals : {
          Sid       = "AllowPrincipal${replace(principal, "/[^A-Za-z0-9]/", "")}"
          Effect    = "Allow"
          Principal = contains(keys(permissions), "arn") ? { AWS = permissions.arn } : { Service = permissions.service }
          Action    = permissions.actions
          Resource = contains(keys(permissions), "include_bucket_resource") && permissions.include_bucket_resource ? [
            aws_s3_bucket.main.arn,
            "${aws_s3_bucket.main.arn}/*"
          ] : ["${aws_s3_bucket.main.arn}/*"]
          Condition = contains(keys(permissions), "condition") ? permissions.condition : null
        }
      ] : [],
      
      # Custom policy statements
      #var.custom_policy_statements
    )
  })
}