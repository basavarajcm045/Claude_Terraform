# modules/s3/main.tf - Comprehensive S3 bucket module with security and compliance

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

#========== S3 Bucket ==========

# Generate unique bucket name if not provided
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name != "" ? var.bucket_name : "${local.bucket_prefix}-${random_string.bucket_suffix.result}"

  tags = merge(
    local.default_tags,
    {
      Name = var.bucket_name != "" ? var.bucket_name : "${local.bucket_prefix}-bucket"
    }
  )
}

#========== BUCKET VERSIONING ==========

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status     = var.enable_versioning ? "Enabled" : "Suspended"
    mfa_delete = var.enable_versioning && var.enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

#========== ENCRYPTION ==========

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm      = var.encryption_type == "kms" ? "aws:kms" : "AES256"
      kms_master_key_id  = var.encryption_type == "kms" && var.kms_key_id != "" ? var.kms_key_id : null
    }
    bucket_key_enabled = var.bucket_key_enabled
  }
}

# KMS Key for S3 (if not provided externally)
resource "aws_kms_key" "s3" {
  count                   = var.encryption_type == "kms" && var.kms_key_id == "" ? 1 : 0
  description             = "KMS key for ${aws_s3_bucket.main.id} encryption"
  deletion_window_in_days = var.kms_deletion_window
  enable_key_rotation     = true
  policy                  = var.kms_custom_policy != "" ? var.kms_custom_policy : null

  tags = merge(
    local.default_tags,
    {
      Name = "${local.bucket_prefix}-kms-key"
    }
  )
}

resource "aws_kms_alias" "s3" {
  count         = var.encryption_type == "kms" && var.kms_key_id == "" ? 1 : 0
  name          = "alias/${local.bucket_prefix}-s3-key"
  target_key_id = aws_kms_key.s3[0].key_id
}

#========== PUBLIC ACCESS BLOCK ==========

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

#========== ACL ==========

resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = var.acl

  depends_on = [aws_s3_bucket_public_access_block.main]
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
      var.custom_policy_statements
    )
  })
}

#========== LOGGING ==========

# S3 bucket for access logs
resource "aws_s3_bucket" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = var.log_bucket_name != "" ? var.log_bucket_name : "${local.bucket_prefix}-logs-${random_string.bucket_suffix.result}"

  tags = merge(
    local.default_tags,
    {
      Name = "${local.bucket_prefix}-logs"
    }
  )
}

# Logging bucket public access block
resource "aws_s3_bucket_public_access_block" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logging bucket ACL
resource "aws_s3_bucket_acl" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id
  acl    = "log-delivery-write"

  depends_on = [aws_s3_bucket_public_access_block.logging]
}

# Logging bucket versioning
resource "aws_s3_bucket_versioning" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Logging bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable logging on main bucket
resource "aws_s3_bucket_logging" "main" {
  count          = var.enable_logging ? 1 : 0
  bucket         = aws_s3_bucket.main.id
  target_bucket  = aws_s3_bucket.logging[0].id
  target_prefix  = var.log_prefix

  depends_on = [
    aws_s3_bucket_acl.logging,
    aws_s3_bucket_public_access_block.logging
  ]
}

# Lifecycle policy for logging bucket
resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    expiration {
      days = var.log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.log_retention_days
    }
  }
}

#========== LIFECYCLE CONFIGURATION ==========

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      # Filtering
      dynamic "filter" {
        for_each = rule.value.filters != null ? [rule.value.filters] : []
        content {
          and {
            prefix = try(filter.value.prefix, "")
            tags   = try(filter.value.tags, {})
          }
        }
      }

      # Transitions
      dynamic "transition" {
        for_each = try(rule.value.transitions, [])
        content {
          days          = try(transition.value.days, null)
          date          = try(transition.value.date, null)
          storage_class = transition.value.storage_class
        }
      }

      # Noncurrent version transitions
      dynamic "noncurrent_version_transition" {
        for_each = try(rule.value.noncurrent_version_transitions, [])
        content {
          noncurrent_days = noncurrent_version_transition.value.noncurrent_days
          storage_class   = noncurrent_version_transition.value.storage_class
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

      # Noncurrent version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = try(rule.value.noncurrent_version_expiration, null) != null ? [rule.value.noncurrent_version_expiration] : []
        content {
          noncurrent_days = noncurrent_version_expiration.value.noncurrent_days
        }
      }

      # Abort incomplete multipart upload
      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(rule.value.abort_incomplete_multipart_upload, null) != null ? [rule.value.abort_incomplete_multipart_upload] : []
        content {
          days_after_initiation = abort_incomplete_multipart_upload.value.days_after_initiation
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

#========== CORS CONFIGURATION ==========

resource "aws_s3_bucket_cors_configuration" "main" {
  count  = var.enable_cors ? 1 : 0
  bucket = aws_s3_bucket.main.id

  dynamic "cors_rule" {
    for_each = var.cors_rules
    content {
      allowed_headers = cors_rule.value.allowed_headers
      allowed_methods = cors_rule.value.allowed_methods
      allowed_origins = cors_rule.value.allowed_origins
      expose_headers  = try(cors_rule.value.expose_headers, [])
      max_age_seconds = try(cors_rule.value.max_age_seconds, 3000)
    }
  }
}

#========== REPLICATION CONFIGURATION ==========

resource "aws_s3_bucket_replication_configuration" "main" {
  count  = var.enable_replication ? 1 : 0
  bucket = aws_s3_bucket.main.id
  role   = aws_iam_role.replication[0].arn

  depends_on = [aws_s3_bucket_versioning.main]

  dynamic "rule" {
    for_each = var.replication_rules
    content {
      id       = rule.value.id
      priority = rule.value.priority
      status   = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = try(rule.value.prefix, "")
      }

      destination {
        bucket       = rule.value.destination_bucket
        storage_class = try(rule.value.destination_storage_class, null)

        dynamic "replication_time" {
          for_each = try(rule.value.enable_replication_time, false) ? [1] : []
          content {
            status = "Enabled"
            time {
              minutes = try(rule.value.replication_time_minutes, 15)
            }
          }
        }

        dynamic "metrics" {
          for_each = try(rule.value.enable_metrics, false) ? [1] : []
          content {
            status = "Enabled"
            event_threshold {
              minutes = try(rule.value.metrics_time_minutes, 15)
            }
          }
        }
      }

      dynamic "delete_marker_replication" {
        for_each = try(rule.value.replicate_delete_markers, false) ? [1] : []
        content {
          status = "Enabled"
        }
      }
    }
  }
}

# IAM role for replication
resource "aws_iam_role" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${local.bucket_prefix}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })

  tags = local.default_tags
}

resource "aws_iam_role_policy" "replication" {
  count = var.enable_replication ? 1 : 0
  name  = "${local.bucket_prefix}-replication-policy"
  role  = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${replace(var.replication_rules[0].destination_bucket, var.replication_rules[0].destination_bucket, "${var.replication_rules[0].destination_bucket}/*")}*"
      }
    ]
  })
}

#========== OBJECT LOCK ==========

# Note: Must be enabled at bucket creation. This is a workaround
resource "aws_s3_bucket_object_lock_configuration" "main" {
  count = var.enable_object_lock ? 1 : 0
  bucket = aws_s3_bucket.main.id

  rule {
    default_retention {
      mode = var.object_lock_default_mode
      days = try(var.object_lock_default_days, null)
      years = try(var.object_lock_default_years, null)
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

#========== REQUEST METRICS ==========

resource "aws_s3_bucket_metric" "entire_bucket" {
  count  = var.enable_metrics ? 1 : 0
  bucket = aws_s3_bucket.main.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_metric" "by_storage_class" {
  count  = var.enable_metrics ? 1 : 0
  bucket = aws_s3_bucket.main.id
  name   = "ByStorageClass"

  filter {
    and {
      prefix = ""
      tags   = {}
    }
  }
}

#========== INVENTORY CONFIGURATION ==========

resource "aws_s3_bucket_inventory" "main" {
  count                    = var.enable_inventory ? 1 : 0
  bucket                   = aws_s3_bucket.main.id
  name                     = "${local.bucket_prefix}-inventory"
  included_object_versions = "All"
  enabled                  = true

  optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "ETag",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus"
  ]

  schedule {
    frequency = var.inventory_frequency
  }

  destination {
    bucket {
      format     = var.inventory_format
      bucket_arn = aws_s3_bucket.main.arn
      prefix     = "inventory-reports/"

      encryption {
        sse_kms {
          key_id = var.encryption_type == "kms" ? (var.kms_key_id != "" ? var.kms_key_id : aws_kms_key.s3[0].arn) : null
        }
      }
    }
  }
}

#========== REQUEST PAYMENT ==========

resource "aws_s3_bucket_request_payment_configuration" "main" {
  count = var.enable_request_payment ? 1 : 0
  bucket = aws_s3_bucket.main.id
  payer = "Requester"
}

#========== VERSIONING CONTROL - OBJECT LOCK ==========

resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  count  = var.enable_intelligent_tiering ? 1 : 0
  bucket = aws_s3_bucket.main.id
  name   = "AutoArchive"

  status = "Enabled"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = var.intelligent_tiering_archive_days
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = var.intelligent_tiering_deep_archive_days
  }
}

#========== TAGS ==========

resource "aws_s3_bucket_tagging" "main" {
  bucket = aws_s3_bucket.main.id

  tagging {
    tags = merge(
      local.default_tags,
      {
        Name = aws_s3_bucket.main.id
      }
    )
  }
}

#========== MONITORING & ALARMS ==========

resource "aws_cloudwatch_metric_alarm" "bucket_size" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${local.bucket_prefix}-bucket-size-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.bucket_size_threshold_bytes
  alarm_description   = "Alert when bucket size exceeds threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = aws_s3_bucket.main.id
    StorageType = "StandardStorage"
  }
}

resource "aws_cloudwatch_metric_alarm" "object_count" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${local.bucket_prefix}-object-count-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.object_count_threshold
  alarm_description   = "Alert when number of objects exceeds threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = aws_s3_bucket.main.id
    StorageType = "AllStorageTypes"
  }
}
