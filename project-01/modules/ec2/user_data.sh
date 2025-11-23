#!/bin/bash
# EC2 User Data Script - Runs on instance startup

set -e  # Exit on error

# Variables from Terraform
PROJECT_NAME="${project_name}"
ENVIRONMENT="${environment}"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/user-data.log
}

log "Starting user data script for $PROJECT_NAME-$ENVIRONMENT"

# Update system packages
log "Updating system packages..."
yum update -y

# Install basic tools
log "Installing basic tools..."
yum install -y \
    curl \
    wget \
    git \
    htop \
    vim \
    net-tools \
    telnet \
    unzip \
    openssl \
    jq

# Install Docker
log "Installing Docker..."
amazon-linux-extras install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
log "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
log "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip aws

# Install CloudWatch agent
log "Installing CloudWatch agent..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
rm -f amazon-cloudwatch-agent.rpm

# Install Node.js (optional - comment out if not needed)
log "Installing Node.js..."
amazon-linux-extras install -y nodejs14

# Install Python3 and pip
log "Installing Python3..."
yum install -y python3 python3-pip
pip3 install --upgrade pip
pip3 install \
    boto3 \
    requests \
    mysql-connector-python \
    psycopg2-binary

# Install MySQL client tools
log "Installing MySQL client..."
yum install -y mysql

# Install PostgreSQL client (optional)
log "Installing PostgreSQL client..."
yum install -y postgresql

# Create application directory
log "Creating application directory..."
mkdir -p /opt/app
chown -R ec2-user:ec2-user /opt/app

# Create log directory
mkdir -p /var/log/app
chown -R ec2-user:ec2-user /var/log/app

# Configure CloudWatch Logs agent
log "Configuring CloudWatch Logs..."
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "metrics": {
    "namespace": "$PROJECT_NAME-$ENVIRONMENT",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          {
            "name": "cpu_usage_idle",
            "rename": "CPU_USAGE_IDLE",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MEM_USED_PERCENT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DISK_USED_PERCENT",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/app/*.log",
            "log_group_name": "/aws/ec2/$PROJECT_NAME-$ENVIRONMENT",
            "log_stream_name": "{instance_id}"
          },
          {
            "file_path": "/var/log/cloud-init-output.log",
            "log_group_name": "/aws/ec2/$PROJECT_NAME-$ENVIRONMENT",
            "log_stream_name": "cloud-init/{instance_id}"
          }
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create system information file
log "Creating system information file..."
cat > /opt/app/system-info.json <<EOF
{
  "project": "$PROJECT_NAME",
  "environment": "$ENVIRONMENT",
  "instance_id": "$(ec2-metadata --instance-id | cut -d ' ' -f 2)",
  "availability_zone": "$(ec2-metadata --availability-zone | cut -d ' ' -f 2)",
  "ami_id": "$(ec2-metadata --ami-id | cut -d ' ' -f 2)",
  "instance_type": "$(ec2-metadata --instance-type | cut -d ' ' -f 2)",
  "private_ip": "$(ec2-metadata --local-ipv4 | cut -d ' ' -f 2)",
  "setup_time": "$(date -Iseconds)"
}
EOF

# Set permissions
chmod 644 /opt/app/system-info.json
chown ec2-user:ec2-user /opt/app/system-info.json

# Create a health check script
log "Creating health check script..."
cat > /opt/app/health-check.sh <<'HEALTH_EOF'
#!/bin/bash
# Simple health check script

echo "=== System Health Check ==="
echo "Timestamp: $(date)"
echo ""

echo "=== CPU Usage ==="
top -bn1 | grep "Cpu(s)" | awk '{print $2}'

echo ""
echo "=== Memory Usage ==="
free -m | grep Mem

echo ""
echo "=== Disk Usage ==="
df -h / | tail -1

echo ""
echo "=== Running Processes ==="
ps aux | wc -l

echo ""
echo "=== Network Interfaces ==="
ip addr show | grep "inet "
HEALTH_EOF

chmod +x /opt/app/health-check.sh
chown ec2-user:ec2-user /opt/app/health-check.sh

# Create cron job for periodic health checks
log "Setting up cron jobs..."
echo "0 * * * * /opt/app/health-check.sh >> /var/log/app/health-check.log 2>&1" | crontab -u ec2-user -

# Final message
log "User data script completed successfully!"
log "Instance is ready for use"

# Write completion marker
touch /opt/app/setup-complete
chown ec2-user:ec2-user /opt/app/setup-complete

log "All setup completed at $(date)"