# modules/s3/main.tf

# Generate unique bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  lower   = true
}

# Main S3 Bucket
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-bucket-${var.environment}-${random_string.bucket_suffix.result}"

  tags = merge(
    var.tags,
    {
      Name = var.bucket_name != "" ? var.bucket_name : "${var.project_name}-bucket-${var.environment}"
    }
  )
}

# Versioning
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public Access Block
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = var.enable_public_access_block
  block_public_policy     = var.enable_public_access_block
  ignore_public_acls      = var.enable_public_access_block
  restrict_public_buckets = var.enable_public_access_block
}

# ACL
resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"

  depends_on = [aws_s3_bucket_public_access_block.main]
}

# Logging Bucket (for S3 access logs)
resource "aws_s3_bucket" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = var.log_bucket_name != "" ? var.log_bucket_name : "${var.project_name}-logs-${var.environment}-${random_string.bucket_suffix.result}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-logs-${var.environment}"
    }
  )
}

# Logging bucket ACL
resource "aws_s3_bucket_acl" "logging" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id
  acl    = "log-delivery-write"
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

# Enable logging on main bucket
resource "aws_s3_bucket_logging" "main" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.main.id

  target_bucket = aws_s3_bucket.logging[0].id
  target_prefix = "logs/"

  depends_on = [aws_s3_bucket_acl.logging]
}

# Lifecycle Rules
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = var.lifecycle_transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.lifecycle_expiration_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_expiration_days
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# CORS Configuration (optional - if serving web content)
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag", "x-amz-version-id"]
    max_age_seconds = 3000
  }
}

# Bucket Policy - Deny unencrypted uploads
resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedObjectUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.main.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
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
    ]
  })
}

# CloudWatch Metrics
resource "aws_s3_bucket_metric" "entire_bucket" {
  bucket = aws_s3_bucket.main.id
  name   = "EntireBucket"
}