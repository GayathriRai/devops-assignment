output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_security_group_id" {
  description = "Security group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "Security group ID for the application"
  value       = aws_security_group.app.id
}

output "database_security_group_id" {
  description = "Security group ID for PostgreSQL"
  value       = aws_security_group.database.id
}

output "rds_endpoint" {
  description = "PostgreSQL RDS endpoint"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "PostgreSQL RDS port"
  value       = aws_db_instance.postgres.port
}

output "ec2_instance_id" {
  description = "Todo application EC2 instance ID"
  value       = aws_instance.app.id
}

output "ec2_public_ip" {
  description = "Todo application EC2 public IP"
  value       = aws_instance.app.public_ip
}

output "ec2_public_dns" {
  description = "Todo application EC2 public DNS"
  value       = aws_instance.app.public_dns
}

output "ec2_security_group_id" {
  description = "Security group ID for Todo application EC2"
  value       = aws_security_group.ec2.id
}