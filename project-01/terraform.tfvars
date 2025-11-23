# terraform.tfvars - Environment-specific values

project_name = "myapp"
environment  = "dev"
aws_region   = "us-east-1"

# VPC Configuration
vpc_cidr            = "10.0.0.0/16"
availability_zones  = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
enable_nat_gateway  = true

# EC2 Configuration
instance_type   = "t3.micro"
instance_count  = 2
key_pair_name   = "my-key-pair"  # Create this manually or via Terraform
ami_filter      = "amzn2-ami-hvm-*-x86_64-gp2"
enable_public_ip = true
root_volume_size = 20
root_volume_type = "gp3"

# Security
allowed_ssh_cidr = "0.0.0.0/0"  # Change this to your IP for security

# RDS Configuration
db_allocated_storage   = 20
db_engine              = "mysql"
db_engine_version      = "8.0.35"
db_instance_class      = "db.t3.micro"
db_name                = "myappdb"
db_username            = "admin"
db_password            = "ChangeMe123!"
db_multi_az            = false
db_skip_final_snapshot = true
db_backup_retention_period = 7
db_publicly_accessible = false
db_port                = 3306

# S3 Configuration
s3_bucket_name                = "myapp-bucket-dev-12345"  # Must be globally unique
s3_enable_versioning          = true
s3_enable_sse                 = true
s3_enable_public_access_block = true
s3_enable_logging             = true
s3_log_bucket_name            = "myapp-logs-dev-12345"
s3_lifecycle_transition_days  = 90
s3_lifecycle_expiration_days  = 365

# IAM Configuration
create_s3_user = true
s3_user_name   = "myapp-s3-user"
create_ec2_role = true
ec2_role_name  = "myapp-ec2-role"