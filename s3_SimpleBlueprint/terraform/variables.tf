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

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs for access"
  type        = list(string)
  default     = []
}