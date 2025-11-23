# modules/iam/outputs.tf

output "ec2_role_arn" {
  description = "EC2 IAM role ARN"
  value       = try(aws_iam_role.ec2[0].arn, "")
}

output "ec2_role_name" {
  description = "EC2 IAM role name"
  value       = try(aws_iam_role.ec2[0].name, "")
}

output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = try(aws_iam_instance_profile.ec2[0].name, "")
}

output "ec2_instance_profile_arn" {
  description = "EC2 instance profile ARN"
  value       = try(aws_iam_instance_profile.ec2[0].arn, "")
}

output "s3_user_name" {
  description = "IAM user name for S3"
  value       = try(aws_iam_user.s3_user[0].name, "")
  sensitive   = true
}

output "s3_user_arn" {
  description = "IAM user ARN for S3"
  value       = try(aws_iam_user.s3_user[0].arn, "")
}

output "s3_access_key_id" {
  description = "S3 user access key ID"
  value       = try(aws_iam_access_key.s3_user[0].id, "")
  sensitive   = true
}

output "s3_access_key_secret" {
  description = "S3 user secret access key (store securely)"
  value       = try(aws_iam_access_key.s3_user[0].secret, "")
  sensitive   = true
}

output "s3_credentials_secret_arn" {
  description = "AWS Secrets Manager ARN for S3 credentials"
  value       = try(aws_secretsmanager_secret.s3_user_credentials[0].arn, "")
}