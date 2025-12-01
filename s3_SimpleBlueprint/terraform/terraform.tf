#========== EXAMPLE 1: Development Bucket - Minimal Security ==========

module "s3_dev" {
  source = "./modules/s3"

  project_name = "myapp"
  environment  = "dev"
  bucket_name  = "myapp-dev-bucket-${data.aws_caller_identity.current.account_id}"

  # Basic security
  enable_versioning          = true
  enable_logging             = false
  block_public_acls          = true
  block_public_policy        = true
  ignore_public_acls         = true
  restrict_public_buckets    = true
  
  # Encryption
  encryption_type = "aes256"
  
  # Lifecycle - Archive after 60 days
  lifecycle_rules = [
    {
      id      = "archive-objects"
      enabled = true
      transitions = [
        {
          days          = 60
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 365
      }
    }
  ]

  # Disable advanced features
  enable_cors                 = false
  enable_replication          = false
  enable_object_lock          = false
  enable_cloudwatch_alarms    = true

  tags = {
    Team       = "Engineering"
    CostCenter = "Development"
  }
}

#========== EXAMPLE 2: Production Bucket - Maximum Security & Compliance ==========

module "s3_prod" {
  source = "./modules/s3"

  project_name = "myapp"
  environment  = "prod"
  bucket_name  = "myapp-prod-bucket-${data.aws_caller_identity.current.account_id}"

  # Enhanced security
  enable_versioning          = true
  enable_mfa_delete          = false  # Requires root account setup
  block_public_acls          = true
  block_public_policy        = true
  ignore_public_acls         = true
  restrict_public_buckets    = true
  enforce_ssl                = true
  enforce_encrypted_uploads  = true

  # KMS encryption
  encryption_type           = "kms"
  kms_key_id                = ""  # Auto-create KMS key
  bucket_key_enabled        = true

  # Comprehensive logging
  enable_logging   = true
  log_prefix       = "audit-logs/"
  log_retention_days = 2555  # 7 years for compliance

  # Lifecycle - Strict archival for compliance
  lifecycle_rules = [
    {
      id      = "archive-immediately"
      enabled = true
      transitions = [
        {
          days          = 30
          storage_class = "GLACIER"
        },
        {
          days          = 90
          storage_class = "DEEP_ARCHIVE"
        }
      ]
      noncurrent_version_transitions = [
        {
          noncurrent_days = 7
          storage_class   = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        noncurrent_days = 365
      }
      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]

  # Cross-region replication for disaster recovery
  enable_replication = true
  replication_rules = [
    {
      id                        = "replicate-all"
      priority                  = 1
      enabled                   = true
      prefix                    = ""
      destination_bucket        = "arn:aws:s3:::myapp-prod-backup-${data.aws_caller_identity.current.account_id}"
      destination_storage_class = "STANDARD_IA"
      enable_replication_time   = true
      replication_time_minutes  = 15
      replicate_delete_markers  = true
    }
  ]

  # Object lock for compliance
  enable_object_lock         = true
  object_lock_default_mode   = "COMPLIANCE"
  object_lock_default_years  = 7

  # Advanced features
  enable_metrics             = true
  enable_inventory           = true
  inventory_frequency        = "Daily"
  inventory_format           = "Parquet"
  enable_intelligent_tiering = true
  enable_cloudwatch_alarms   = true
  bucket_size_threshold_bytes = 1099511627776  # 1TB

  # Policy for EC2 instances to access
  allow_principals = {
    "ec2-app-role" = {
      arn                        = "arn:aws:iam::123456789012:role/ec2-app-role"
      actions                    = ["s3:GetObject", "s3:PutObject"]
      include_bucket_resource    = false
    }
  }

  tags = {
    Team       = "Engineering"
    CostCenter = "Production"
    Compliance = "GDPR,HIPAA"
  }
}

#========== EXAMPLE 3: Data Lake Bucket - Optimized for Analytics ==========

module "s3_datalake" {
  source = "./modules/s3"

  project_name = "analytics"
  environment  = "prod"
  bucket_name  = "analytics-datalake-${data.aws_caller_identity.current.account_id}"

  # Versioning for data recovery
  enable_versioning = true

  # KMS for sensitive data
  encryption_type = "kms"

  # Comprehensive logging
  enable_logging = true

  # Intelligent lifecycle management
  lifecycle_rules = [
    # Raw data - frequent access
    {
      id      = "raw-data-tier"
      enabled = true
      prefix  = "raw/"
      transitions = []
    },
    # Processed data - transition after 90 days
    {
      id      = "processed-data-tier"
      enabled = true
      prefix  = "processed/"
      transitions = [
        {
          days          = 90
          storage_class = "INTELLIGENT_TIERING"
        }
      ]
      expiration = {
        days = 2555
      }
    },
    # Archived data - deep archive
    {
      id      = "archived-data-tier"
      enabled = true
      prefix  = "archive/"
      transitions = [
        {
          days          = 30
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    }
  ]

  # Intelligent tiering for automatic cost optimization
  enable_intelligent_tiering        = true
  intelligent_tiering_archive_days  = 90
  intelligent_tiering_deep_archive_days = 180

  # Inventory for data discovery
  enable_inventory   = true
  inventory_format   = "Parquet"
  inventory_frequency = "Daily"

  # Metrics for monitoring
  enable_metrics = true
  enable_cloudwatch_alarms = true
  object_count_threshold = 10000000  # 10M objects

  # CORS for analytics tools
  enable_cors = true
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD", "PUT", "POST", "DELETE"]
      allowed_origins = ["https://analytics.example.com"]
      expose_headers  = ["ETag", "x-amz-meta-custom-header"]
      max_age_seconds = 3000
    }
  ]

  # Requester pays for external users
  enable_request_payment = false

  tags = {
    Team       = "Data"
    Purpose    = "Analytics"
    CostCenter = "Data-Engineering"
  }
}

#========== EXAMPLE 4: Static Website Hosting ==========

module "s3_website" {
  source = "./modules/s3"

  project_name = "website"
  environment  = "prod"
  bucket_name  = "website-${data.aws_caller_identity.current.account_id}"

  # Public read access for website
  acl = "public-read"
  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false

  # Versioning for rollback
  enable_versioning = true

  # Basic encryption
  encryption_type = "aes256"

  # Logging
  enable_logging = true

  # CORS for CDN
  enable_cors = true
  cors_rules = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      max_age_seconds = 3000
    }
  ]

  # Lifecycle for assets
  lifecycle_rules = [
    {
      id      = "delete-old-assets"
      enabled = true
      transitions = [
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]
      expiration = {
        days = 1825  # 5 years
      }
    }
  ]

  enable_metrics = true

  tags = {
    Team = "Frontend"
    Purpose = "Website"
  }
}

#========== EXAMPLE 5: Backup Bucket - Read-Only Replica ==========

module "s3_backup" {
  source = "./modules/s3"

  project_name = "myapp"
  environment  = "prod"
  bucket_name  = "myapp-backup-${data.aws_caller_identity.current.account_id}"

  # Immutable for backup protection
  enable_versioning  = true
  enable_object_lock = true
  object_lock_default_mode = "COMPLIANCE"
  object_lock_default_years = 7

  # Strong encryption
  encryption_type = "kms"

  # Logging
  enable_logging = true

  # Minimal lifecycle - keep everything
  lifecycle_rules = [
    {
      id      = "clean-incomplete-uploads"
      enabled = true
      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]

  # Inventory for audit
  enable_inventory = true

  # CloudWatch monitoring
  enable_cloudwatch_alarms = true
  bucket_size_threshold_bytes = 5497558138880  # 5TB

  # Deny all public access
  enforce_ssl                = true
  enforce_encrypted_uploads  = true
  block_public_acls          = true
  block_public_policy        = true
  ignore_public_acls         = true
  restrict_public_buckets    = true

  tags = {
    Team       = "Infrastructure"
    Purpose    = "Backup"
    Criticality = "High"
  }
}

#========== DATA SOURCE ==========

data "aws_caller_identity" "current" {}
