# environments/prod.tfvars - Production environment

project_name = "myapp"
environment  = "prod"
aws_region   = "us-east-1"

# VPC
vpc_cidr             = "10.1.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24", "10.1.12.0/24"]
enable_nat_gateway   = true

# EC2
instance_type       = "t3.small"
instance_count      = 3
key_pair_name       = "prod-key-pair"
ami_filter          = "amzn2-ami-hvm-*-x86_64-gp2"
enable_public_ip    = false
root_volume_size    = 50
root_volume_type    = "gp3"
allowed_ssh_cidr    = "10.1.0.0/16"

# RDS
db_allocated_storage   = 100
db_engine              = "mysql"
db_engine_version      = "8.0.35"
db_instance_class      = "db.t3.small"
db_name                = "myappprod"
db_username            = "prodadmin"
db_password            = "ProdPassword123!Secure"
db_multi_az            = true
db_skip_final_snapshot = false
db_backup_retention_period = 30
db_publicly_accessible = false

# S3
s3_bucket_name                = "myapp-prod-bucket-12345"
s3_enable_versioning          = true
s3_enable_sse                 = true
s3_enable_public_access_block = true
s3_enable_logging             = true
s3_log_bucket_name            = "myapp-prod-logs-12345"
s3_lifecycle_transition_days  = 90
s3_lifecycle_expiration_days  = 365

# IAM
create_s3_user = true
s3_user_name   = "myapp-s3-prod-user"
create_ec2_role = true
ec2_role_name  = "myapp-ec2-prod-role"