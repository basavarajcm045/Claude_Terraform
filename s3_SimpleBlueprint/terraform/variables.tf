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

variable "bucket_name_logging" {
  description = "S3 bucket name for store logs(if empty, a unique name will be generated)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
  default     = true
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

variable "cost_center" {
  description = "Cost center tag value"
  type        = string
}