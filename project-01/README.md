# Claude_Terraform

# Terraform AWS Infrastructure Project

This is a production-ready Terraform project that provisions a complete AWS infrastructure including VPC, EC2, RDS, S3, NAT Gateway, Internet Gateway, and IAM resources.

## Project Structure

```
terraform/
├── main.tf                 # Root orchestration
├── variables.tf            # Root variables
├── outputs.tf              # Root outputs
├── terraform.tfvars        # Default values
├── providers.tf            # Provider configuration
│
├── modules/
│   ├── vpc/               # VPC, subnets, IGW, NAT Gateway
│   ├── security_groups/   # Security groups for EC2, RDS, ALB
│   ├── ec2/               # EC2 instances
│   ├── rds/               # RDS database
│   ├── s3/                # S3 buckets with logging and lifecycle
│   └── iam/               # IAM roles, users, and policies
│
└── environments/          # Environment-specific configurations
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **SSH Key Pair** created in AWS (for EC2 access)

## Key Features

### VPC & Networking
- Custom VPC with configurable CIDR
- Public subnets with Internet Gateway
- Private subnets with NAT Gateway
- Network ACLs for additional security
- Multi-AZ deployment support

### EC2 Instances
- Auto-scaling group ready configuration
- CloudWatch monitoring enabled
- IMDSv2 enforced for security
- IAM instance profile attached
- EBS encryption enabled
- CloudWatch alarms for CPU utilization

### RDS Database
- Encrypted at rest with KMS
- Automated backups
- Multi-AZ support (production)
- Enhanced monitoring
- CloudWatch alarms
- Parameter groups for optimization

### S3 Storage
- Versioning support
- Server-side encryption (SSE)
- Public access blocking
- Access logging capability
- Lifecycle rules (transition to Glacier)
- Security policies (deny unencrypted uploads)
- Metrics enabled

### IAM Security
- EC2 role with S3 and CloudWatch access
- S3-specific IAM user with access keys
- Credentials stored in AWS Secrets Manager
- CloudWatch Logs permissions
- SSM Session Manager support (no SSH needed)

## Quick Start

### 1. Clone and Setup

```bash
cd terraform
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Create SSH Key Pair (if not exists)

```bash
aws ec2 create-key-pair --key-name dev-key-pair --region us-east-1 \
  --query 'KeyMaterial' --output text > dev-key-pair.pem
chmod 600 dev-key-pair.pem
```

### 4. Update terraform.tfvars

Edit `terraform.tfvars` with your values:
- Set `s3_bucket_name` (must be globally unique)
- Set `key_pair_name` to your AWS key pair name
- Update `allowed_ssh_cidr` to your IP

### 5. Plan Infrastructure

```bash
# For development
terraform plan -var-file="terraform.tfvars"

# For specific environment
terraform plan -var-file="environments/prod.tfvars"
```

### 6. Apply Infrastructure

```bash
terraform apply -var-file="terraform.tfvars"
```

### 7. Retrieve Outputs

```bash
# Get all outputs
terraform output

# Get specific output
terraform output ec2_instance_public_ips
terraform output rds_endpoint
terraform output s3_bucket_name
```

## Managing Different Environments

### Development Environment

```bash
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"
```

### Production Environment

```bash
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

## Accessing Resources

### EC2 Instances

Using SSH:
```bash
ssh -i dev-key-pair.pem ec2-user@<public-ip>
```

Using AWS Systems Manager Session Manager:
```bash
aws ssm start-session --target i-1234567890abcdef0 --region us-east-1
```

### RDS Database

From EC2 instance:
```bash
mysql -h <rds-endpoint> -u admin -p myappdb
```

### S3 Bucket

Using AWS CLI:
```bash
# List objects
aws s3 ls s3://myapp-bucket-dev-12345/

# Upload file
aws s3 cp file.txt s3://myapp-bucket-dev-12345/

# Download file
aws s3 cp s3://myapp-bucket-dev-12345/file.txt .
```

Using S3 User Credentials:
```bash
# Get credentials from Secrets Manager
aws secretsmanager get-secret-value --secret-id myapp-s3-user-credentials
```

## S3 IAM User Permissions

The created IAM user has the following permissions:

### Full Access
- GetObject
- PutObject
- DeleteObject
- ListBucket
- GetBucketVersioning
- Multipart upload operations

### Restrictions
- Access only to specified bucket
- No cross-bucket access
- Credentials rotatable via access keys

## Variable Reference

### Common Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| project_name | string | "myapp" | Project name for resource naming |
| environment | string | "dev" | Environment (dev, staging, prod) |
| aws_region | string | "us-east-1" | AWS region |

### VPC Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| vpc_cidr | string | "10.0.0.0/16" | VPC CIDR block |
| enable_nat_gateway | bool | true | Enable NAT Gateway |

### EC2 Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| instance_type | string | "t3.micro" | EC2 instance type |
| instance_count | number | 2 | Number of instances |
| key_pair_name | string | "" | SSH key pair name |

### RDS Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| db_engine | string | "mysql" | Database engine |
| db_instance_class | string | "db.t3.micro" | RDS instance class |
| db_multi_az | bool | false | Enable Multi-AZ |

### S3 Variables
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| s3_bucket_name | string | "" | S3 bucket name |
| s3_enable_versioning | bool | true | Enable versioning |
| s3_enable_sse | bool | true | Enable encryption |

## Outputs Reference

Important outputs after apply:

```hcl
vpc_id                    # VPC ID
public_subnet_ids         # Public subnet IDs
private_subnet_ids        # Private subnet IDs
ec2_instance_ids          # EC2 instance IDs
ec2_instance_public_ips   # EC2 public IPs
rds_endpoint              # RDS database endpoint
rds_port                  # RDS database port
s3_bucket_name            # S3 bucket name
iam_s3_user_name          # IAM user for S3
iam_s3_access_key_id      # S3 user access key
iam_ec2_role_arn          # EC2 role ARN
```

## Cleanup

To destroy all resources:

```bash
terraform destroy -var-file="terraform.tfvars"
```

**Warning**: This will delete all resources including RDS database (unless skip_final_snapshot is false).

## Best Practices

1. **State Management**
   - Use S3 backend for remote state (uncomment in providers.tf)
   - Enable state locking with DynamoDB
   - Never commit terraform.tfstate to git

2. **Security**
   - Restrict allowed_ssh_cidr to your IP
   - Use IAM roles instead of access keys where possible
   - Rotate S3 user credentials regularly
   - Enable MFA on AWS account

3. **Cost Optimization**
   - Use t3 instances for development (burstable)
   - Disable Multi-AZ for non-production
   - Set appropriate backup retention
   - Use lifecycle policies for S3

4. **Monitoring**
   - Check CloudWatch alarms regularly
   - Review CloudWatch Logs
   - Monitor S3 metrics
   - Set up SNS notifications for alarms

## Troubleshooting

### VPC/Subnet Issues
```bash
# List VPCs
aws ec2 describe-vpcs

# List subnets
aws ec2 describe-subnets
```

### EC2 Issues
```bash
# Check instance status
aws ec2 describe-instance-status

# View user data logs
ssh -i key.pem ec2-user@<ip> "sudo tail -f /var/log/cloud-init-output.log"
```

### RDS Issues
```bash
# Check database status
aws rds describe-db-instances

# View database logs
aws rds describe-db-log-files --db-instance-identifier myapp-rds-dev
```

### S3 Issues
```bash
# Check bucket properties
aws s3api get-bucket-versioning --bucket bucket-name

# Check bucket policy
aws s3api get-bucket-policy --bucket bucket-name
```

## License

MIT License

## Support

For issues or questions, refer to:
- Terraform AWS Provider: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS Documentation: https://docs.aws.amazon.com