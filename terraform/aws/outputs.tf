output "s3_bucket_name" {
  description = "Name of the raw data lake bucket."
  value       = aws_s3_bucket.raw_datalake.id
}

output "s3_bucket_arn" {
  description = "ARN of the raw data lake bucket."
  value       = aws_s3_bucket.raw_datalake.arn
}

output "airflow_iam_role_arn" {
  description = "IAM role ARN assumed by Airflow worker instances."
  value       = aws_iam_role.airflow_orchestration_role.arn
}
