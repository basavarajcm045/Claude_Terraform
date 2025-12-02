# S3 Module Documentation

Comprehensive Terraform module for provisioning AWS S3 buckets with advanced security, lifecycle management, and compliance features.

## Table of Contents

1. [Features](#features)
2. [Module Structure](#module-structure)
3. [Quick Start](#quick-start)
4. [Configuration Guide](#configuration-guide)
5. [Security Features](#security-features)
6. [Compliance & Standards](#compliance--standards)
7. [Examples](#examples)
8. [Troubleshooting](#troubleshooting)

## Features

### 🔒 Security
- ✅ Server-side encryption (AES256 or KMS)
- ✅ SSL/TLS enforcement
- ✅ Public access blocking
- ✅ Bucket policies with least privilege
- ✅ IAM access controls
- ✅ Versioning and MFA delete protection
- ✅ Object lock for compliance
- ✅ Encrypted logging

### 📊 Lifecycle Management
- ✅ Automatic object archival
- ✅ Storage class transitions (S3, IA, Glacier, Deep Archive)
- ✅ Expiration policies
- ✅ Noncurrent version management
- ✅ Incomplete multipart upload cleanup
- ✅ Intelligent tiering

### 📋 Compliance & Governance
- ✅ Access logging with audit trail
- ✅ Inventory reports (CSV, Parquet, ORC)
- ✅ CloudWatch metrics and alarms
- ✅ Object lock (GOVERNANCE or COMPLIANCE mode)
- ✅ Cross-region replication
- ✅ Retention policies
- ✅ Compliance summary reporting

### 🛠️ Advanced Features
- ✅ CORS configuration
- ✅ Cross-region replication
- ✅ Request metrics
- ✅ Inventory reports
- ✅ Intelligent tiering
- ✅ Requester pays mode
- ✅ CloudWatch alarms
- ✅ Custom bucket policies

## Module Structure

```
modules/s3/
├── main.tf              # Core bucket and resources
├── variables.tf         # Input variables
├── outputs.tf          # Output values
└── README.md           # This file
```

## Quick Start

### Basic Usage

```hcl
module "s3_bucket" {
  source = "./modules/s3"

  project_name = "myapp"
  environment  = "dev"
  bucket_name  = "myapp-dev-bucket"

  tags = {
    Team = "Engineering"
  }
}
```

### Get Bucket Information

```bash
terraform output -from-module=./modules/s3
```

## Configuration Guide

### Basic Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `project_name` | string | - | Project name (required) |
| `environment` | string | - | Environment (dev, staging, prod) |
| `bucket_name` | string | "" | Bucket name (auto-generated if empty) |
| `tags` | map | {} | Common tags |

### Versioning

Enable versioning for data protection and recovery:

```hcl
enable_versioning = true
enable_mfa_delete = false  # Requires root account setup
```

### Encryption

**AES256 (Default)**
```hcl
encryption_type = "aes256"
```

**KMS (Recommended for sensitive data)**
```hcl
encryption_type = "kms"
kms_key_id      = ""  # Auto-create or provide existing key
bucket_key_enabled = true  # Reduces KMS API calls
```

### Public Access Control

Block all public access (recommended):

```hcl
acl                     = "private"
block_public_acls       = true
block_public_policy     = true
ignore_public_acls      = true
restrict_public_buckets = true
```

Allow public read-only:

```hcl
acl                     = "public-read"
block_public_acls       = false
block_public_policy     = false
ignore_public_acls      = false
restrict_public_buckets = false
```

### Logging Configuration

Enable access logging for audit trails:

```hcl
enable_logging     = true
log_prefix         = "access-logs/"
log_retention_days = 2555  # 7 years
```

### Lifecycle Rules

Archive and delete objects based on age:

```hcl
lifecycle_rules = [
  {
    id      = "archive-old-objects"
    enabled = true
    prefix  = ""
    
    # Transition to cheaper storage
    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      },
      {
        days          = 365
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    
    # Delete after 7 years
    expiration = {
      days = 2555
    }
    
    # Clean old versions
    noncurrent_version_expiration = {
      noncurrent_days = 90
    }
    
    # Clean incomplete uploads
    abort_incomplete_multipart_upload = {
      days_after_initiation = 7
    }
  }
]
```

### Replication (Disaster Recovery)

Enable cross-region replication:

```hcl
enable_replication = true
replication_rules = [
  {
    id                        = "replicate-all"
    priority                  = 1
    enabled                   = true
    prefix                    = ""
    destination_bucket        = "arn:aws:s3:::backup-bucket"
    destination_storage_class = "STANDARD_IA"
    enable_replication_time   = true
    replicate_delete_markers  = true
  }
]
```

### CORS Configuration

For web applications:

```hcl
enable_cors = true
cors_rules = [
  {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT"]
    allowed_origins = ["https://example.com"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
]
```

### Object Lock (Compliance)

Prevent object deletion for regulatory requirements:

```hcl
enable_object_lock       = true
object_lock_default_mode = "COMPLIANCE"  # or "GOVERNANCE"
object_lock_default_years = 7
```

## Security Features

### Encryption

**At Rest:**
- AES256 (default, AWS managed)
- KMS (customer managed for more control)

**In Transit:**
- SSL/TLS enforcement via bucket policy

```hcl
enforce_ssl              = true
enforce_encrypted_uploads = true
```

### Access Control

**Via Bucket Policy:**
```hcl
allow_principals = {
  "app-role" = {
    arn     = "arn:aws:iam::123456789012:role/app-role"
    actions = ["s3:GetObject", "s3:PutObject"]
  }
}
```

**Custom Policies:**
```hcl
custom_policy_statements = [
  {
    Sid    = "AllowCloudFront"
    Effect = "Allow"
    Principal = {
      Service = "cloudfront.amazonaws.com"
    }
    Action   = "s3:GetObject"
    Resource = "${aws_s3_bucket.main.arn}/*"
  }
]
```

### Versioning & MFA Delete

```hcl
enable_versioning = true
enable_mfa_delete = true  # Requires root account
```

Note: MFA delete requires root account credentials.

## Compliance & Standards

### GDPR Compliance

```hcl
module "s3_gdpr" {
  source = "./modules/s3"

  project_name = "gdpr-app"
  environment  = "prod"

  # Data protection
  enable_versioning       = true
  encryption_type         = "kms"
  
  # Audit trail
  enable_logging          = true
  log_retention_days      = 2555  # 7 years
  
  # Data retention
  lifecycle_rules = [{
    id      = "delete-after-3-years"
    enabled = true
    expiration = {
      days = 1095
    }
  }]
  
  # Access logging for DPA
  enable_inventory = true
  
  tags = {
    Compliance = "GDPR"
  }
}
```

### HIPAA Compliance

```hcl
module "s3_hipaa" {
  source = "./modules/s3"

  project_name = "hipaa-data"
  environment  = "prod"

  # Encryption required
  encryption_type = "kms"
  enforce_encrypted_uploads = true
  
  # No public access
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  
  # Audit logging
  enable_logging     = true
  enable_inventory   = true
  
  # Object integrity
  enable_versioning = true
  
  # Encryption in transit
  enforce_ssl = true

  tags = {
    Compliance = "HIPAA"
  }
}
```

### PCI-DSS Compliance

```hcl
module "s3_pci" {
  source = "./modules/s3"

  project_name = "pci-data"
  environment  = "prod"

  # Encryption
  encryption_type         = "kms"
  enforce_encrypted_uploads = true
  
  # Logging
  enable_logging        = true
  enable_inventory      = true
  
  # Versioning
  enable_versioning     = true
  
  # SSL
  enforce_ssl           = true
  
  # Lifecycle
  lifecycle_rules = [{
    id      = "delete-pci-data"
    enabled = true
    expiration = {
      days = 365
    }
  }]

  tags = {
    Compliance = "PCI-DSS"
  }
}
```

## Monitoring

### CloudWatch Alarms

Monitor bucket size and object count:

```hcl
enable_cloudwatch_alarms    = true
bucket_size_threshold_bytes = 107374182400  # 100GB
object_count_threshold      = 1000000       # 1M objects
```

### Inventory Reports

Generate regular inventory snapshots:

```hcl
enable_inventory    = true
inventory_frequency = "Daily"
inventory_format    = "Parquet"
```

### Request Metrics

Track API usage:

```hcl
enable_metrics = true
```

## Cost Optimization

### Intelligent Tiering

Automatic cost optimization:

```hcl
enable_intelligent_tiering        = true
intelligent_tiering_archive_days  = 90
intelligent_tiering_deep_archive_days = 180
```

### Storage Transitions

Transition objects to cheaper storage:

```hcl
lifecycle_rules = [{
  id      = "cost-optimization"
  enabled = true
  transitions = [
    {
      days          = 30
      storage_class = "STANDARD_IA"
    },
    {
      days          = 90
      storage_class = "GLACIER"
    }
  ]
}]
```

## Outputs

Key outputs available:

| Output | Description |
|--------|-------------|
| `bucket_id` | S3 bucket name |
| `bucket_arn` | Bucket ARN |
| `bucket_domain_name` | Regional domain name |
| `logging_bucket_id` | Logging bucket name |
| `encryption_type` | Encryption method |
| `kms_key_id` | KMS key ID |
| `compliance_summary` | Compliance status |

## Examples

See `examples.tf` for complete examples:

1. **Development** - Minimal setup with basic security
2. **Production** - Maximum security with compliance
3. **Data Lake** - Analytics-optimized configuration
4. **Website** - Static site hosting
5. **Backup** - Immutable archive bucket

## Troubleshooting

### Issue: Bucket name already exists

**Solution:** S3 bucket names are globally unique. Use auto-generation:

```hcl
bucket_name = ""  # Let Terraform generate
```

### Issue: MFA delete requires setup

**Solution:** MFA delete requires root account credentials. Enable via console first, then use Terraform.

### Issue: Replication errors

**Solution:** Verify destination bucket exists and versioning is enabled:

```bash
# Check destination bucket
aws s3api get-bucket-versioning --bucket destination-bucket

# Enable versioning if needed
aws s3api put-bucket-versioning \
  --bucket destination-bucket \
  --versioning-configuration Status=Enabled
```

### Issue: KMS key access denied

**Solution:** Update KMS key policy to allow S3:

```hcl
kms_custom_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [{
    Sid    = "AllowS3"
    Effect = "Allow"
    Principal = {
      Service = "s3.amazonaws.com"
    }
    Action   = "kms:*"
    Resource = "*"
  }]
})
```

### Issue: Logging bucket permissions

**Solution:** Ensure logging bucket has correct ACL:

```bash
aws s3api put-bucket-acl \
  --bucket logging-bucket \
  --acl log-delivery-write
```

## Best Practices

1. **Always enable versioning** for production buckets
2. **Enforce encryption** (KMS for sensitive data)
3. **Block public access** by default
4. **Enable logging** for audit trails
5. **Implement lifecycle** rules for cost optimization
6. **Use replication** for critical data
7. **Monitor with CloudWatch** alarms
8. **Enable inventory** reports
9. **Apply least privilege** access policies
10. **Tag all buckets** for organization

## References

- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/BestPractices.html)
- [S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [Compliance with S3](https://aws.amazon.com/compliance/)
