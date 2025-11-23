# modules/iam/main.tf - Complete IAM configuration with S3 and EC2 roles

#========== EC2 Role ==========

# EC2 IAM Role (if EC2 needs to access AWS services)
resource "aws_iam_role" "ec2" {
  count           = var.create_ec2_role ? 1 : 0
  name_prefix     = "${var.ec2_role_name}-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2-role-${var.environment}"
    }
  )
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  count       = var.create_ec2_role ? 1 : 0
  name_prefix = "${var.ec2_role_name}-"
  role        = aws_iam_role.ec2[0].name
}

# Policy: EC2 can read/write to S3 bucket
resource "aws_iam_role_policy" "ec2_s3_access" {
  count  = var.create_ec2_role ? 1 : 0
  name   = "${var.project_name}-ec2-s3-policy"
  role   = aws_iam_role.ec2[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Sid    = "S3ListAllBuckets"
        Effect = "Allow"
        Action = "s3:ListAllMyBuckets"
        Resource = "*"
      }
    ]
  })
}

# Policy: EC2 CloudWatch logs and monitoring
resource "aws_iam_role_policy" "ec2_cloudwatch" {
  count  = var.create_ec2_role ? 1 : 0
  name   = "${var.project_name}-ec2-cloudwatch-policy"
  role   = aws_iam_role.ec2[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "CloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# Policy: EC2 SSM Session Manager (for secure shell access without SSH keys)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  count      = var.create_ec2_role ? 1 : 0
  role       = aws_iam_role.ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#========== S3 IAM User ==========

# IAM User for S3-only access
resource "aws_iam_user" "s3_user" {
  count = var.create_s3_user ? 1 : 0
  name  = "${var.s3_user_name}-${var.environment}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-s3-user-${var.environment}"
    }
  )
}

# IAM User Policy: Full S3 Bucket Access
resource "aws_iam_user_policy" "s3_full_access" {
  count  = var.create_s3_user ? 1 : 0
  name   = "${var.project_name}-s3-full-access"
  user   = aws_iam_user.s3_user[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3FullBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:ListBucketVersions",
          "s3:GetBucketLocation",
          "s3:GetBucketTagging"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Sid    = "S3MultipartUpload"
        Effect = "Allow"
        Action = [
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM User Policy: Read-Only S3 Access (alternative)
resource "aws_iam_user_policy" "s3_read_only" {
  count  = var.create_s3_user && false ? 1 : 0  # Set to true if you want read-only instead
  name   = "${var.project_name}-s3-read-only"
  user   = aws_iam_user.s3_user[0].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ReadOnly"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:ListBucketVersions",
          "s3:GetBucketLocation"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Access Keys for S3 User
resource "aws_iam_access_key" "s3_user" {
  count = var.create_s3_user ? 1 : 0
  user  = aws_iam_user.s3_user[0].name

  lifecycle {
    create_before_destroy = true
  }
}

# Store Access Key in AWS Secrets Manager (recommended)
resource "aws_secretsmanager_secret" "s3_user_credentials" {
  count                   = var.create_s3_user ? 1 : 0
  name_prefix             = "${var.project_name}-s3-user-credentials-"
  recovery_window_in_days = 7

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-s3-user-credentials-${var.environment}"
    }
  )
}

resource "aws_secretsmanager_secret_version" "s3_user_credentials" {
  count           = var.create_s3_user ? 1 : 0
  secret_id       = aws_secretsmanager_secret.s3_user_credentials[0].id
  secret_string   = jsonencode({
    access_key_id     = aws_iam_access_key.s3_user[0].id
    secret_access_key = aws_iam_access_key.s3_user[0].secret
    bucket_name       = var.s3_bucket_name
    region            = data.aws_caller_identity.current.account_id
  })
}

#========== Additional Managed Policies ==========

# Attach AWS managed policy for basic EC2 operations
resource "aws_iam_role_policy_attachment" "ec2_basic" {
  count      = var.create_ec2_role ? 1 : 0
  role       = aws_iam_role.ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#========== Data Sources ==========

data "aws_caller_identity" "current" {}