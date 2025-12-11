
#==============BUCKET 1: Development Bucket - Maximum security and compliance===========#

data "aws_caller_identity" "current" {}

module "s3_dev" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  #account_id   = data.aws_caller_identity.current.account_id
  bucket_name   = var.bucket_name
  force_destroy = false

  #------versioning and Basic security-----------#

  enable_versioning  = true
  versioning_enabled = true
  enable_mfa_delete  = false
  #enable_logging         = false
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true
  enforce_ssl               = true
  enforce_encrypted_uploads = true

  # Encryption
  encryption_type     = "sse-s3"
  kms_key_id          = ""
  bucket_key_enabled  = false
  kms_deletion_window = 30
  kms_custom_policy   = ""
  #enable_encryption         = true.    # use this for production

  # Object lock for compliance
  enable_object_lock       = true
  object_lock_default_mode = "COMPLIANCE" #var.object_lock_default_mode
  object_lock_default_days = 30           #var.object_lock_default_days

  # Lifecycle - Archive after 60 days
  lifecycle_rules = [
    {
      id      = "object-archieve"
      enabled = true
      #prefix  = "logs/"

      transitions = [
        { days = 30, storage_class = "STANDARD_IA" },
        { days = 60, storage_class = "GLACIER" }

      ]
      expiration = {
        days = 365
      }
    }
  ]

  #lifecycle_rules = [
  #{
  #id               = "glacier-transition"
  #enabled          = true
  #prefix           = "logs/"
  #transitions_days = 30
  #storage_class    = "GLACIER"
  #expiration_days  = 365
  #enabled          = true
  #}
  #]

  #lifecycle_rules = var.lifecycle_rules 



  #------Tags-----------#
  tags = {
    Team       = "Engineering"
    CostCenter = var.cost_center
  }
}

#=========================BUCKET 2: Logging Bucket===============#

module "s3_dev_log" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  #account_id   = data.aws_caller_identity.current.account_id
  bucket_name   = var.bucket_name_logging
  force_destroy = false

  #------versioning and Basic security-----------#

  enable_versioning  = true
  versioning_enabled = true
  enable_mfa_delete  = false
  #enable_logging         = false
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true
  enforce_ssl               = true
  enforce_encrypted_uploads = true

  # Encryption
  encryption_type     = "sse-s3"
  kms_key_id          = ""
  bucket_key_enabled  = false
  kms_deletion_window = 30
  kms_custom_policy   = ""

  #enable_encryption         = true.    # use this for production

  enable_object_lock       = false
  object_lock_default_mode = "COMPLIANCE"
  object_lock_default_days = 30
}

#========== BUCKET 3: Backup Bucket - Read-Only Replica ==========#

module "s3_backup" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  bucket_name  = "myapp-backup-${data.aws_caller_identity.current.account_id}"

  #------versioning and Basic security-----------#

  versioning_enabled = true
  enable_mfa_delete  = false

  # Encryption
  kms_key_id          = ""
  bucket_key_enabled  = false
  kms_deletion_window = 30
  kms_custom_policy   = ""
  #enable_encryption         = true.    # use this for production

  # Immutable for backup protection
  enable_versioning        = true
  enable_object_lock       = true
  object_lock_default_mode = "COMPLIANCE"
  object_lock_default_days = 30
  #object_lock_default_years = 7

  # Strong encryption
  encryption_type = "kms"

  # Logging
  #enable_logging = true

  # Minimal lifecycle - keep everything
  lifecycle_rules = [
    {
      id      = "clean-incomplete-uploads"
      enabled = true
      #prefix  = "backups/"

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]

  # Deny all public access
  enforce_ssl               = true
  enforce_encrypted_uploads = true
  block_public_acls         = true
  block_public_policy       = true
  ignore_public_acls        = true
  restrict_public_buckets   = true

  # Inventory for audit
  #enable_inventory = true

  # CloudWatch monitoring
  #enable_cloudwatch_alarms = true
  #bucket_size_threshold_bytes = 5497558138880  # 5TB

  tags = {
    Team        = "Infrastructure"
    Purpose     = "Backup"
    Criticality = "High"
  }
}

#========== BUCKET 4: Static Website Hosting ==========

/*module "s3_website" {
  source = "./modules/s3"

  project_name = "website"
  environment  = "prod"
  bucket_name  = "website-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  # Website hosting configuration 
  //enable_website_hosting = true
  //index_document        = "index.html"
  //error_document        = "error.html"
  //website_redirect_all_requests_to = null
  //website_routing_rules = null

  # Public read access for website content
  acl = "public-read"
  block_public_acls         = false
  block_public_policy       = false
  ignore_public_acls        = false
  restrict_public_buckets   = false
  #enforce_ssl               = false
  #enforce_encrypted_uploads = false

  # No versioning or object lock needed
  # versioning for rollbacks
  enable_versioning  = true
  enable_object_lock = true

  # Basic encryption
  encryption_type = "aes256"

  # Logging
  enable_logging = true

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




}*/