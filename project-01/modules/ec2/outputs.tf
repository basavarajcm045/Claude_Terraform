# modules/ec2/outputs.tf

output "instance_ids" {
  description = "EC2 instance IDs"
  value       = aws_instance.main[*].id
}

output "instance_public_ips" {
  description = "EC2 instance public IPs"
  value       = aws_instance.main[*].public_ip
}

output "instance_private_ips" {
  description = "EC2 instance private IPs"
  value       = aws_instance.main[*].private_ip
}

output "instance_arns" {
  description = "EC2 instance ARNs"
  value       = aws_instance.main[*].arn
}