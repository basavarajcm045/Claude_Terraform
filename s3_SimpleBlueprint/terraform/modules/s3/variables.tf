variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name (if empty, a unique name will be generated)"
  type        = string
}

variable "force_destroy" {
  description = "A boolean that indicates all objects should be deleted from the bucket so that the buxket can be destroyed without error"
  type        = bool
  default     = false
}

#variable "account_id" {
  #description = "AWS Account ID"
  #type        = string
#}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
}

variable "enable_mfa_delete" {
  description = "Enable MFA delete for the S3 bucket (requires versioning to be enabled)"
  type        = bool
  
}

#=======Object Lock==============
variable "enable_object_lock" {
  description = "Enable S3 Object Lock at bucket creation (force new if changed to true)"
  type        = bool
}

variable "object_lock_default_mode" {
  description = "Default object lock mode: GOVERNANCE or COMPLIANCE"
  type        = string
}

variable "object_lock_default_days" {
  description = "Default retention period (days) for object lock"
  type        = number
}

#variable "object_lock_default_years" {
  #description = "Default retention period (Year/s) for object lock"
  #type        = number
  #default     = 1
#}

variable "block_public_acls" {
  description = "Block public ACLs for the S3 bucket"
  type        = bool
  
}

variable "block_public_policy" {
  description = "Block public bucket policies for the S3 bucket"
  type        = bool
  
}

variable "ignore_public_acls" {
  description = "Ignore public ACLs for the S3 bucket"
  type        = bool
  
}

variable "restrict_public_buckets" {
  description = "Restrict public buckets for the S3 bucket"
  type        = bool
  
}

#variable "acl" {
  #description = "Canned ACL to apply to the S3 bucket"
  #type        = string
  #default     = "private"
  
#}

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

variable "enforce_encrypted_uploads" {
  description = "Enforce encrypted uploads to the S3 bucket"
  type        = bool
  
}

variable "enforce_ssl" {
  description = "Enforce SSL for requests to the S3 bucket"
  type        = bool 
  
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

#========Encryption Variables ========

variable "encryption_type" {
  description = "Type of encryption for the S3 bucket (none, sse-s3, kms)"
  type        = string
}

variable "kms_key_id" {
  description = "KMS Key ID for KMS encryption (if null, AES256 will be used)"
  type        = string
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

#===============

#variable "custom_policy_statements" {
  #description = ""
  
#}