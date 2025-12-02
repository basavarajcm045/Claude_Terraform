variable "project_name" {
  description = "Project name"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "S3 bucket name (if empty, a unique name will be generated)"
  type        = string
  default     = "tescoimsdevtu"
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete for the S3 bucket (requires versioning to be enabled)"
  type        = bool
  default     = false

}

variable "block_public_acls" {
  description = "Block public ACLs for the S3 bucket"
  type        = bool
  default     = true

}

variable "enable_logging" {
  description = "Enable server access logging for the S3 bucket"
  type        = bool
  default     = false

}

variable "block_public_policy" {
  description = "Block public bucket policies for the S3 bucket"
  type        = bool
  default     = true

}

variable "ignore_public_acls" {
  description = "Ignore public ACLs for the S3 bucket"
  type        = bool
  default     = true

}

variable "restrict_public_buckets" {
  description = "Restrict public buckets for the S3 bucket"
  type        = bool
  default     = true

}

variable "acl" {
  description = "Canned ACL to apply to the S3 bucket"
  type        = string
  default     = "private"

}

variable "enforce_encrypted_uploads" {
  description = "Enforce encrypted uploads to the S3 bucket"
  type        = bool
  default     = true

}

variable "enforce_ssl" {
  description = "Enforce SSL for requests to the S3 bucket"
  type        = bool
  default     = true

}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for the S3 bucket"
  type = list(object({
    id      = string
    enabled = bool
    prefix  = string
    transitions = list(object({
      days          = number
      storage_class = string
    }))
    expiration = object({
      days = number
    })
  }))
  default = []
}

variable "encryption_type" {
  description = "Type of encryption for the S3 bucket (none, sse-s3, kms)"
  type        = string
  default     = "sse-s3"
}

variable "kms_key_id" {
  description = "KMS Key ID for KMS encryption"
  type        = string
  default     = ""
}

variable "bucket_key_enabled" {
  description = "Enable S3 Bucket Key for KMS encryption"
  type        = bool
  default     = false
}

variable "kms_deletion_window" {
  description = "KMS Key deletion window in days"
  type        = number
  default     = 30
}

variable "kms_custom_policy" {
  description = "Custom KMS Key policy"
  type        = string
  default     = ""
}