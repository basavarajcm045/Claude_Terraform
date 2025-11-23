# modules/security_groups/main.tf

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name_prefix = "${var.project_name}-ec2-sg-"
  description = "Security group for EC2 instances"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-ec2-sg-${var.environment}"
    }
  )
}

# EC2 Inbound SSH
resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.ec2.id
  description       = "SSH from allowed CIDR"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.allowed_ssh_cidr

  tags = {
    Name = "${var.project_name}-ec2-ssh-${var.environment}"
  }
}

# EC2 Inbound HTTP
resource "aws_vpc_security_group_ingress_rule" "ec2_http" {
  security_group_id = aws_security_group.ec2.id
  description       = "HTTP from anywhere"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-ec2-http-${var.environment}"
  }
}

# EC2 Inbound HTTPS
resource "aws_vpc_security_group_ingress_rule" "ec2_https" {
  security_group_id = aws_security_group.ec2.id
  description       = "HTTPS from anywhere"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-ec2-https-${var.environment}"
  }
}

# EC2 Outbound all traffic
resource "aws_vpc_security_group_egress_rule" "ec2_all" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow all outbound traffic"

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-ec2-egress-${var.environment}"
  }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-sg-"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-rds-sg-${var.environment}"
    }
  )
}

# RDS Inbound from EC2
resource "aws_vpc_security_group_ingress_rule" "rds_from_ec2" {
  security_group_id = aws_security_group.rds.id
  description       = "Database access from EC2"

  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ec2.id

  tags = {
    Name = "${var.project_name}-rds-from-ec2-${var.environment}"
  }
}

# RDS Inbound from same security group (for cluster connections)
resource "aws_vpc_security_group_ingress_rule" "rds_from_self" {
  security_group_id = aws_security_group.rds.id
  description       = "Database access from same security group"

  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds.id

  tags = {
    Name = "${var.project_name}-rds-from-self-${var.environment}"
  }
}

# RDS Outbound all traffic
resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-rds-egress-${var.environment}"
  }
}

# ALB Security Group (if needed for future use)
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-alb-sg-"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-alb-sg-${var.environment}"
    }
  )
}

# ALB Inbound HTTP
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from anywhere"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-alb-http-${var.environment}"
  }
}

# ALB Inbound HTTPS
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from anywhere"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-alb-https-${var.environment}"
  }
}

# ALB Outbound all traffic
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow all outbound traffic"

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "${var.project_name}-alb-egress-${var.environment}"
  }
}