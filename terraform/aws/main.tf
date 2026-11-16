terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Modern-Enterprise-Pipeline"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# S3 DATA LAKE - RAW INGESTION STORAGE
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "raw_datalake" {
  bucket        = var.bucket_name
  force_destroy = var.environment != "prod"
}

# Enable bucket versioning for data auditing and recovery
resource "aws_s3_bucket_versioning" "raw_datalake_versioning" {
  bucket = aws_s3_bucket.raw_datalake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Default Server-Side Encryption (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "raw_datalake_encryption" {
  bucket = aws_s3_bucket.raw_datalake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "raw_datalake_public_block" {
  bucket = aws_s3_bucket.raw_datalake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Lifecycle Policy: Transition raw payloads to Glacier after 90 days to optimize storage costs
resource "aws_s3_bucket_lifecycle_configuration" "raw_datalake_lifecycle" {
  bucket = aws_s3_bucket.raw_datalake.id

  rule {
    id     = "archive-old-raw-data"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 180
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# LEAST-PRIVILEGE IAM ROLE & POLICY FOR AIRFLOW ORCHESTRATION
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "airflow_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "airflow_orchestration_role" {
  name               = "enterprise-mds-airflow-${var.environment}-role"
  assume_role_policy = data.aws_iam_policy_document.airflow_assume_role.json
}

data "aws_iam_policy_document" "airflow_s3_least_privilege" {
  statement {
    sid = "AllowBucketListing"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.raw_datalake.arn]
  }

  statement {
    sid = "AllowObjectReadWrite"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.raw_datalake.arn}/*"]
  }
}

resource "aws_iam_policy" "airflow_s3_policy" {
  name        = "enterprise-mds-airflow-s3-${var.environment}-policy"
  description = "Allows Airflow workers to read/write raw JSON payloads in S3 data lake."
  policy      = data.aws_iam_policy_document.airflow_s3_least_privilege.json
}

resource "aws_iam_role_policy_attachment" "airflow_attach" {
  role       = aws_iam_role.airflow_orchestration_role.name
  policy_arn = aws_iam_policy.airflow_s3_policy.arn
}
