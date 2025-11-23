# Root main.tf - Orchestrates all modules

module "vpc" {
  source = "./modules/vpc"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  enable_nat_gateway    = var.enable_nat_gateway

  tags = local.common_tags
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id           = module.vpc.vpc_id
  project_name     = var.project_name
  environment      = var.environment
  allowed_ssh_cidr = var.allowed_ssh_cidr
  db_port          = var.db_port

  tags = local.common_tags
}

module "ec2" {
  source = "./modules/ec2"

  project_name              = var.project_name
  environment               = var.environment
  instance_type             = var.instance_type
  key_pair_name             = var.key_pair_name
  ami_filter                = var.ami_filter
  instance_count            = var.instance_count
  subnet_ids                = module.vpc.public_subnet_ids
  security_group_id         = module.security_groups.ec2_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  enable_public_ip          = var.enable_public_ip
  root_volume_size          = var.root_volume_size
  root_volume_type          = var.root_volume_type

  tags = local.common_tags

  depends_on = [module.iam]
}

module "rds" {
  source = "./modules/rds"

  project_name              = var.project_name
  environment               = var.environment
  allocated_storage         = var.db_allocated_storage
  engine                    = var.db_engine
  engine_version            = var.db_engine_version
  instance_class            = var.db_instance_class
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = var.db_password
  subnet_ids                = module.vpc.private_subnet_ids
  vpc_security_group_ids    = [module.security_groups.rds_security_group_id]
  multi_az                  = var.db_multi_az
  skip_final_snapshot       = var.db_skip_final_snapshot
  backup_retention_period   = var.db_backup_retention_period
  publicly_accessible       = var.db_publicly_accessible

  tags = local.common_tags
}

module "s3" {
  source = "./modules/s3"

  project_name                   = var.project_name
  environment                    = var.environment
  bucket_name                    = var.s3_bucket_name
  enable_versioning              = var.s3_enable_versioning
  enable_server_side_encryption  = var.s3_enable_sse
  enable_public_access_block     = var.s3_enable_public_access_block
  enable_logging                 = var.s3_enable_logging
  log_bucket_name                = var.s3_log_bucket_name
  lifecycle_transition_days      = var.s3_lifecycle_transition_days
  lifecycle_expiration_days      = var.s3_lifecycle_expiration_days

  tags = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  project_name           = var.project_name
  environment            = var.environment
  s3_bucket_arn          = module.s3.s3_bucket_arn
  s3_bucket_name         = module.s3.s3_bucket_name
  create_s3_user         = var.create_s3_user
  s3_user_name           = var.s3_user_name
  create_ec2_role        = var.create_ec2_role
  ec2_role_name          = var.ec2_role_name

  tags = local.common_tags
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = timestamp()
  }
}