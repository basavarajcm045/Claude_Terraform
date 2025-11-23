# modules/rds/main.tf

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name_prefix    = "${var.project_name}-rds-subnet-group-"
  subnet_ids     = var.subnet_ids
  
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-subnet-group-${var.environment}"
    }
  )
}

# RDS Parameter Group
resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.project_name}-rds-params-"
  family      = var.engine == "mysql" ? "mysql8.0" : var.engine == "postgres" ? "postgres15" : "mariadb10.6"

  # Example parameters - customize based on your needs
  dynamic "parameter" {
    for_each = var.engine == "mysql" ? [
      { name = "slow_query_log", value = "1" },
      { name = "long_query_time", value = "2" }
    ] : []
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-param-group-${var.environment}"
    }
  )
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-rds-${var.environment}"
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.db_name
  username = var.username
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.vpc_security_group_ids

  parameter_group_name = aws_db_parameter_group.main.name

  multi_az               = var.multi_az
  publicly_accessible    = var.publicly_accessible
  skip_final_snapshot    = var.skip_final_snapshot
  final_snapshot_identifier = "${var.project_name}-rds-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  backup_retention_period = var.backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  deletion_protection = var.environment == "prod" ? true : false
  copy_tags_to_snapshot = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-${var.environment}"
    }
  )
}

# KMS Key for RDS Encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-kms-key-${var.environment}"
    }
  )
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-rds-${var.environment}"
  target_key_id = aws_kms_key.rds.key_id
}

# IAM Role for RDS Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name_prefix = "${var.project_name}-rds-monitoring-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-monitoring-role-${var.environment}"
    }
  )
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project_name}-rds-cpu-alarm-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU utilization too high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage" {
  alarm_name          = "${var.project_name}-rds-storage-alarm-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648  # 2GB
  alarm_description   = "RDS free storage space too low"
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }
}