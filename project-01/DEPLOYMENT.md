# Terraform Deployment & Usage Guide

Complete step-by-step guide for deploying and managing your AWS infrastructure.

## Prerequisites Checklist

- [ ] AWS Account created with billing enabled
- [ ] IAM user with AdministratorAccess or equivalent permissions
- [ ] AWS credentials configured locally (`aws configure`)
- [ ] Terraform 1.0+ installed (`terraform version`)
- [ ] AWS CLI v2 installed (`aws --version`)
- [ ] Git installed (for version control)
- [ ] Text editor (VS Code recommended with Terraform extension)

## Step 1: Prepare Environment Variables

Create a `.env` file in the terraform directory:

```bash
#!/bin/bash
export AWS_PROFILE=default
export AWS_REGION=us-east-1
export TF_VAR_project_name=myapp
export TF_VAR_environment=dev
```

Load it:
```bash
source .env
```

## Step 2: Set Up AWS Credentials

Verify AWS credentials are configured:

```bash
# Check configured profiles
aws configure list

# Test connectivity
aws sts get-caller-identity
```

Expected output:
```json
{
  "UserId": "AIDAI...",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

## Step 3: Create EC2 Key Pair

Create an SSH key pair for EC2 access:

```bash
# Create key pair
aws ec2 create-key-pair \
  --key-name dev-key-pair \
  --region us-east-1 \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/dev-key-pair.pem

# Set permissions
chmod 600 ~/.ssh/dev-key-pair.pem

# Verify
ls -la ~/.ssh/dev-key-pair.pem
```

## Step 4: Configure terraform.tfvars

Edit `terraform.tfvars` with your specific values:

```hcl
# Must change these
s3_bucket_name = "myapp-bucket-$(date +%s)"  # Must be globally unique
key_pair_name  = "dev-key-pair"

# Recommended to change
project_name = "myapp"
environment  = "dev"
allowed_ssh_cidr = "YOUR_IP/32"  # Use your actual IP for security

# Optional - use defaults
instance_type = "t3.micro"
db_instance_class = "db.t3.micro"
```

To find your IP:
```bash
curl https://checkip.amazonaws.com
```

## Step 5: Initialize Terraform

Initialize the Terraform working directory:

```bash
cd terraform

# Initialize with local backend
terraform init

# To use S3 backend (recommended for production):
# 1. Create S3 bucket and DynamoDB table first
# 2. Uncomment backend configuration in providers.tf
# 3. Run: terraform init
```

Expected output:
```
Initializing the backend...
Initializing modules...
* development
Terraform has been successfully initialized!
```

## Step 6: Validate Configuration

Validate Terraform files:

```bash
# Validate syntax
terraform validate

# Format check
terraform fmt -check -recursive

# Fix formatting
terraform fmt -recursive
```

## Step 7: Plan Infrastructure

Create and review execution plan:

```bash
# Standard plan
terraform plan -out=tfplan

# With specific variables file
terraform plan -var-file="environments/dev.tfvars" -out=tfplan

# Show plan in JSON
terraform show -json tfplan | jq .

# Review specific resource
terraform plan | grep aws_rds_instance
```

## Step 8: Review Plan Output

Key things to verify in the plan:
- [ ] Correct number of resources being created (80-100 expected)
- [ ] Correct instance types for EC2 and RDS
- [ ] VPC CIDR and subnets match your requirements
- [ ] S3 bucket has correct settings
- [ ] IAM users and roles are created

Example resources that should appear:
- 1x VPC
- 2-3x Subnets (public/private)
- 1x Internet Gateway
- 1-3x NAT Gateways
- 2-3x EC2 instances
- 1x RDS database
- 2x S3 buckets (main + logs)
- 3x IAM users/roles
- Multiple security groups

## Step 9: Apply Infrastructure

Deploy the infrastructure:

```bash
# Apply from saved plan (recommended)
terraform apply tfplan

# Or apply directly (requires confirmation)
terraform apply -var-file="terraform.tfvars"

# Non-interactive apply (use with caution)
terraform apply -auto-approve -var-file="terraform.tfvars"
```

This will typically take 10-15 minutes.

Expected output:
```
Apply complete! Resources added: 87, changed: 0, destroyed: 0

Outputs:
ec2_instance_ids = [...]
rds_endpoint = [...]
s3_bucket_name = [...]
```

## Step 10: Retrieve Outputs

Get connection details:

```bash
# All outputs
terraform output

# Specific output
terraform output -raw ec2_instance_public_ips
terraform output -raw rds_endpoint
terraform output -raw s3_bucket_name

# In JSON format
terraform output -json | jq .
```

Create a local reference file:
```bash
terraform output > deployment-outputs.txt
```

## Step 11: Connect to EC2

### Option 1: Using SSH (Traditional)

```bash
# Get instance IPs
EC2_IP=$(terraform output -raw ec2_instance_public_ips | head -1)

# SSH into instance
ssh -i ~/.ssh/dev-key-pair.pem ec2-user@$EC2_IP

# Verify instance setup
cat /opt/app/system-info.json
```

### Option 2: Using AWS Systems Manager Session Manager

```bash
# Get instance ID
INSTANCE_ID=$(terraform output -raw ec2_instance_ids | head -1)

# Start session
aws ssm start-session --target $INSTANCE_ID --region us-east-1

# No SSH key needed!
```

## Step 12: Verify Database Connection

From EC2 instance, test RDS connection:

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

# Test connection
mysql -h $RDS_ENDPOINT -u admin -p -e "SELECT VERSION();"

# List databases
mysql -h $RDS_ENDPOINT -u admin -p -e "SHOW DATABASES;"
```

## Step 13: Test S3 Bucket

```bash
# Get bucket name
S3_BUCKET=$(terraform output -raw s3_bucket_name)

# List objects
aws s3 ls s3://$S3_BUCKET/

# Upload test file
echo "Hello from Terraform" > test.txt
aws s3 cp test.txt s3://$S3_BUCKET/test.txt

# Verify upload
aws s3 ls s3://$S3_BUCKET/test.txt
```

## Step 14: Access S3 User Credentials

Retrieve IAM user credentials for S3-only access:

```bash
# Get credentials from Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id myapp-s3-user-credentials \
  --query SecretString \
  --output text | jq .

# Extract specific values
aws secretsmanager get-secret-value \
  --secret-id myapp-s3-user-credentials \
  --query 'SecretString' \
  --output text | jq -r '.access_key_id'
```

Configure AWS CLI with S3 user credentials:

```bash
# Create new profile
aws configure --profile s3-user
# Enter access key ID
# Enter secret access key
# Enter region

# Test S3 access
aws s3 ls --profile s3-user
```

## Monitoring & Maintenance

### View CloudWatch Logs

```bash
# List log groups
aws logs describe-log-groups | jq '.logGroups[].logGroupName'

# Tail EC2 logs
aws logs tail /aws/ec2/myapp-dev --follow

# Query logs
aws logs start-query \
  --log-group-name /aws/ec2/myapp-dev \
  --start-time 1609459200 \
  --end-time 1609545600 \
  --query-string "fields @timestamp, @message | stats count() by @message"
```

### Monitor RDS

```bash
# Check database status
aws rds describe-db-instances \
  --db-instance-identifier myapp-rds-dev \
  --query 'DBInstances[0].[DBInstanceStatus,Engine,DBInstanceClass]'

# View recent events
aws rds describe-events \
  --source-identifier myapp-rds-dev \
  --source-type db-instance \
  --query 'Events[0:5]'
```

### Monitor S3

```bash
# Get bucket metrics
aws s3api get-bucket-versioning --bucket $S3_BUCKET

# Check lifecycle rules
aws s3api get-bucket-lifecycle-configuration --bucket $S3_BUCKET

# Get bucket size
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name BucketSizeBytes \
  --dimensions Name=BucketName,Value=$S3_BUCKET \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 86400 \
  --statistics Average
```

## Updating Infrastructure

### Modify Variables

```bash
# Edit terraform.tfvars
vi terraform.tfvars

# Plan changes
terraform plan -out=tfplan

# Review changes
terraform show tfplan

# Apply changes
terraform apply tfplan
```

### Add Modules

Update `main.tf` to add new modules, then:

```bash
terraform init
terraform plan
terraform apply
```

## Scaling Resources

### Scale EC2 Instances

```bash
# Change instance_count in terraform.tfvars
instance_count = 5

# Apply
terraform apply -var-file="terraform.tfvars"
```

### Scale RDS Storage

```bash
# Change allocated_storage
db_allocated_storage = 100

# Apply (will cause brief downtime)
terraform apply -var-file="terraform.tfvars"
```

## Backup & Disaster Recovery

### Export State File

```bash
# Backup state file
cp terraform.tfstate terraform.tfstate.backup

# Store in S3
aws s3 cp terraform.tfstate s3://backup-bucket/terraform-state/
```

### Create RDS Snapshot

```bash
aws rds create-db-snapshot \
  --db-instance-identifier myapp-rds-dev \
  --db-snapshot-identifier myapp-rds-dev-snapshot-$(date +%Y%m%d)
```

### Copy S3 Bucket

```bash
# Create replica
aws s3 sync s3://$S3_BUCKET s3://backup-bucket/
```

## Destroying Infrastructure

### Destroy All Resources

```bash
# Plan destruction
terraform destroy -var-file="terraform.tfvars"

# Destroy (requires confirmation)
terraform destroy -var-file="terraform.tfvars"

# Non-interactive destroy
terraform destroy -auto-approve -var-file="terraform.tfvars"
```

### Selective Destruction

```bash
# Destroy specific resource
terraform destroy -target aws_instance.main[0]

# Destroy module
terraform destroy -target module.s3
```

## Troubleshooting

### Common Issues

**Issue: "Error: S3 bucket already exists"**
```bash
# Solution: S3 bucket names must be globally unique
# Generate new name with timestamp
s3_bucket_name = "myapp-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
```

**Issue: "Error: Key pair does not exist"**
```bash
# Solution: Create the key pair first
aws ec2 create-key-pair --key-name your-key-name
```

**Issue: "Error: VPC limit exceeded"**
```bash
# Solution: Check VPC quota
aws service-quotas list-service-quotas --service-code vpc
```

### Debug Mode

Enable detailed logging:

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log

terraform plan

# Review logs
tail -f terraform-debug.log
```

## Cost Estimation

Estimate monthly costs:

```bash
# Generate cost estimate
terraform plan -var-file="terraform.tfvars" -json | \
  aws ce get-cost-forecast \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metric UNBLENDED_COST \
  --filter file://filter.json
```

Typical monthly costs (dev environment):
- EC2: $10-15
- RDS: $20-30
- S3: $1-5
- NAT Gateway: $20-30
- Data Transfer: $0-10

**Total: ~$50-90/month for development**

## Security Best Practices

1. **Rotate S3 User Credentials Monthly**
   ```bash
   aws iam delete-access-key --user-name s3-user --access-key-id XXXXX
   aws iam create-access-key --user-name s3-user
   ```

2. **Enable MFA on AWS Account**
   ```bash
   # Add MFA device to your user
   aws iam enable-mfa-device --user-name your-user --serial-number arn:aws:iam::123456789012:mfa/your-device --authentication-code1 123456 --authentication-code2 789012
   ```

3. **Restrict SSH Access**
   ```bash
   # Only allow from your IP
   allowed_ssh_cidr = "YOUR_IP/32"
   ```

4. **Enable VPC Flow Logs**
   ```bash
   # Add to VPC module
   resource "aws_flow_log" "main" { ... }
   ```

## Getting Help

- **Terraform Docs**: https://www.terraform.io/docs
- **AWS Provider Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest
- **AWS Support**: https://console.aws.amazon.com/support
- **Stack Overflow**: Tag with `terraform` and `amazon-web-services`