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
 
  tags = merge(
    local.default_tags,
    {
      #Name = var.bucket_name != "" ? var.bucket_name : "${local.bucket_prefix}-bucket"
      #Name = var.bucket_name
      Name = "${local.bucket_prefix}-bucket"

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



