#========== EXAMPLE 1: Development Bucket - Minimal Security ==========

data "aws_caller_identity" "current" {}

module "s3_dev" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  #account_id   = data.aws_caller_identity.current.account_id
  #bucket_name = "myapp-dev-bucket-${data.aws_caller_identity.current.account_id}"
  bucket_name = var.bucket_name


  #------versioning and Basic security-----------#

  #enable_encryption         = true.    # use this for production
  #lifecycle_rules = var.lifecycle_rules 

  enable_versioning = true
  #enable_logging             = false
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Encryption
  #encryption_type = "aes256"


  # Disable advanced features
  #enable_cors                 = false
  #enable_replication          = false
  #enable_object_lock = false
  #enable_cloudwatch_alarms    = true

  tags = {
    Team       = "Engineering"
    CostCenter = "Development"
  }
}
