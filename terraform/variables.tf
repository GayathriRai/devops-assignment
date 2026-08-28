variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "todo-app"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "tododb"
}

variable "db_username" {
  description = "PostgreSQL username"
  type        = string
  default     = "todo_user"
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}