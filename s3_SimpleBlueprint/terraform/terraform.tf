
data "aws_caller_identity" "current" {}

module "s3_dev" {
  source = "./modules/s3"

  project_name  = var.project_name
  environment   = var.environment
  #account_id   = data.aws_caller_identity.current.account_id
  bucket_name   = var.bucket_name
  force_destroy = false

  #------versioning and Basic security-----------#

  enable_versioning = true
  #enable_logging         = false
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  enforce_ssl                = true
  enforce_encrypted_uploads  = true
  
  #------Encryption Settings-----------#

  # Encryption
  #encryption_type = "aes256"

  #enable_encryption         = true.    # use this for production

  # Lifecycle - Archive after 60 days
  lifecycle_rules = [
    {
      id      = "object-archieve"
      enabled = true
      prefix = "logs/"

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
