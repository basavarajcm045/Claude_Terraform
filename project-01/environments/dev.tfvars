# environments/dev.tfvars - Development environment

project_name = "myapp"
environment  = "dev"
aws_region   = "us-east-1"

# VPC
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
enable_nat_gateway   = true

# EC2
instance_type       = "t3.micro"
instance_count      = 1
key_pair_name       = "dev-key-pair"
ami_filter          = "amzn2-ami-hvm-*-x86_64-gp2"
enable_public_ip    = true
root_volume_size    = 20
root_volume_type    = "gp3"
allowed_ssh_cidr    = "0.0.0.0/0"

# RDS
db_allocated_storage   = 20
db_engine              = "mysql"
db_engine_version      = "8.0.35"
db_instance_class      = "db.t3.micro"
db_name                = "myappdev"
db_username            = "admin"
db_password            = "DevPassword123!"
db_multi_az            = false
db_skip_final_snapshot = true
db_backup_retention_period = 3
db_publicly_accessible = false

# S3
s3_bucket_name                = "myapp-dev-bucket-12345"
s3_enable_versioning          = true
s3_enable_sse                 = true
s3_enable_public_access_block = true
s3_enable_logging             = false
s3_log_bucket_name            = ""
s3_lifecycle_transition_days  = 60
s3_lifecycle_expiration_days  = 180

# IAM
create_s3_user = true
s3_user_name   = "myapp-s3-dev-user"
create_ec2_role = true
ec2_role_name  = "myapp-ec2-dev-role"