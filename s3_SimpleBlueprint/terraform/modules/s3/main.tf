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
      #var.allow_principals != {} ? [
        #for principal, permissions in var.allow_principals : {
          #Sid       = "AllowPrincipal${replace(principal, "/[^A-Za-z0-9]/", "")}"
          #Effect    = "Allow"
          #Principal = contains(keys(permissions), "arn") ? { AWS = permissions.arn } : { Service = permissions.service }
          #Action    = permissions.actions
          #Resource = contains(keys(permissions), "include_bucket_resource") && permissions.include_bucket_resource ? [
            #aws_s3_bucket.main.arn,
            #"${aws_s3_bucket.main.arn}/*"
          #] : ["${aws_s3_bucket.main.arn}/*"]
          #Condition = contains(keys(permissions), "condition") ? permissions.condition : null
        #}
      #] : [],
      
      # Custom policy statements
      #var.custom_policy_statements
    #)
  #})
#}



#========== OBJECT LOCK ==========

# Note: Must be enabled at bucket creation. This is a workaround
#resource "aws_s3_bucket_object_lock_configuration" "main" {
  #count = var.enable_object_lock ? 1 : 0
  #bucket = aws_s3_bucket.main.id

  #rule {
    #default_retention {
      #mode = var.object_lock_default_mode
      #days = try(var.object_lock_default_days, null)
      #years = try(var.object_lock_default_years, null)
    #}
  #}

  #depends_on = [aws_s3_bucket_versioning.main]
#}


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

