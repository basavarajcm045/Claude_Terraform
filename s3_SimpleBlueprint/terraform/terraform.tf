#========== EXAMPLE 1: Development Bucket - Minimal Security ==========

module "s3_dev" {
  source = "./modules/s3"

  project_name = "var.project_name"
  environment  = "var.environment"
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

#module "s3_prod" {
  #source = "./modules/s3"

  #project_name = "myapp"
  #environment  = "prod"
  #bucket_name  = "myapp-prod-bucket-${data.aws_caller_identity.current.account_id}"

  # Enhanced security
 

  # KMS encryption
  

  # Comprehensive logging
  # 7 years for compliance

  # Lifecycle - Strict archival for compliance
 

  # Cross-region replication for disaster recovery
  

  # Object lock for compliance
  

  # Advanced features
  

  # Policy for EC2 instances to access
  

  #tags = {
    #Team       = "Engineering"
    #CostCenter = "Production"
    #Compliance = "GDPR,HIPAA"
  #}
#}