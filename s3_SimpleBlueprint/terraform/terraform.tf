
data "aws_caller_identity" "current" {}

module "s3_dev" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
  #account_id   = data.aws_caller_identity.current.account_id
  bucket_name = var.bucket_name


  #------versioning and Basic security-----------#

  enable_versioning = true
  #enable_logging         = false
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  #------Encryption Settings-----------#

  # Encryption
  #encryption_type = "aes256"

  #enable_encryption         = true.    # use this for production
  #lifecycle_rules = var.lifecycle_rules 



  #------Tags-----------#
  tags = {
    Team       = "Engineering"
    CostCenter = var.cost_center
  }
}
