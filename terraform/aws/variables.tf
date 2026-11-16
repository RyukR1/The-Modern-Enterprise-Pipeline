variable "aws_region" {
  description = "AWS deployment region."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Target deployment environment (dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "bucket_name" {
  description = "Globally unique name for the raw S3 data lake storage bucket."
  type        = string
  default     = "enterprise-mds-datalake-raw-prod"
}
