output "s3_bucket_name" {
  description = "The name of the S3 bucket used for Terraform state storage"
  value       = module.s3_bucket.s3_bucket_id
}

output "s3_bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = module.s3_bucket.s3_bucket_arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table used for Terraform state locking"
  value       = module.dynamodb_table.dynamodb_table_id
}

output "dynamodb_table_arn" {
  description = "The ARN of the DynamoDB table"
  value       = module.dynamodb_table.dynamodb_table_arn
}

output "iam_user_name" {
  description = "The IAM user name for the Terraform state user"
  value       = module.iam_user.iam_user_name
}

output "iam_user_arn" {
  description = "The ARN of the IAM user"
  value       = module.iam_user.iam_user_arn
}

output "iam_access_key_id" {
  description = "The access key ID for the IAM user"
  value       = module.iam_user.iam_access_key_id
  sensitive   = true
}

output "iam_access_key_secret" {
  description = "The access key secret for the IAM user"
  value       = module.iam_user.iam_access_key_secret
  sensitive   = true
}
