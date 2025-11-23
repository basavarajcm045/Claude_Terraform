# modules/rds/outputs.tf

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.main.endpoint
  sensitive   = true
}

output "rds_address" {
  description = "RDS database address"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "RDS database port"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "RDS database name"
  value       = aws_db_instance.main.db_name
}

output "rds_instance_id" {
  description = "RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "rds_engine" {
  description = "RDS engine type"
  value       = aws_db_instance.main.engine
}

output "rds_engine_version" {
  description = "RDS engine version"
  value       = aws_db_instance.main.engine_version
}

output "kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = aws_kms_key.rds.id
}