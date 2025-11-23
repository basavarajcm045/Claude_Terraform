# modules/ec2/main.tf

# Get latest AMI
data "aws_ami" "main" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.ami_filter]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instances
resource "aws_instance" "main" {
  count                    = var.instance_count
  ami                      = data.aws_ami.main.id
  instance_type            = var.instance_type
  key_name                 = var.key_pair_name != "" ? var.key_pair_name : null
  subnet_id                = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids   = [var.security_group_id]
  iam_instance_profile     = var.iam_instance_profile_name
  associate_public_ip_address = var.enable_public_ip

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "${var.project_name}-root-volume-${count.index + 1}-${var.environment}"
    }
  }

  monitoring              = true
  ebs_optimized          = false

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 required
    http_put_response_hop_limit = 1
  }

  # Optional: user data script
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
  }))

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-instance-${count.index + 1}-${var.environment}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [var.iam_instance_profile_name]
}

# CloudWatch Alarms for EC2 instances
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count               = var.instance_count
  alarm_name          = "${var.project_name}-cpu-alarm-${count.index + 1}-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when CPU exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.main[count.index].id
  }
}