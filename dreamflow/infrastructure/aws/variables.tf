variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "Project prefix for tagging and naming"
  type        = string
  default     = "dreamflow"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.40.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs for ALB/NAT"
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs for ECS/RDS/ElastiCache"
  type        = list(string)
  default     = ["10.40.11.0/24", "10.40.12.0/24"]
}

variable "api_container_image" {
  description = "Backend container image URI"
  type        = string
}

variable "api_container_port" {
  description = "Container port exposed by backend"
  type        = number
  default     = 3000
}

variable "api_desired_count" {
  description = "Number of ECS tasks for the backend service"
  type        = number
  default     = 2
}

variable "api_task_cpu" {
  description = "ECS Fargate task CPU units"
  type        = number
  default     = 512
}

variable "api_task_memory" {
  description = "ECS Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "db_name" {
  description = "RDS PostgreSQL database name"
  type        = string
  default     = "dreamflow"
}

variable "db_username" {
  description = "RDS PostgreSQL master username"
  type        = string
  default     = "dreamflow_admin"
}

variable "db_password" {
  description = "RDS PostgreSQL master password"
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition = (
      trimspace(var.db_password_secret_arn) != "" ||
      (var.db_password != null && trimspace(var.db_password) != "")
    )
    error_message = "Set either db_password_secret_arn or db_password."
  }
}

variable "db_password_secret_arn" {
  description = "Existing Secrets Manager ARN for DB password (recommended for production)"
  type        = string
  default     = ""
}

variable "db_allocated_storage" {
  description = "RDS storage size in GiB"
  type        = number
  default     = 20
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "smtp_host" {
  description = "SMTP host for enquiry notifications"
  type        = string
  default     = "smtp.gmail.com"
}

variable "smtp_port" {
  description = "SMTP port for enquiry notifications"
  type        = number
  default     = 587
}

variable "smtp_secure" {
  description = "Whether SMTP should use TLS from connect"
  type        = bool
  default     = false
}

variable "smtp_user" {
  description = "SMTP username"
  type        = string
  default     = ""
}

variable "smtp_pass" {
  description = "SMTP password or app password"
  type        = string
  sensitive   = true
  default     = null
}

variable "smtp_password_secret_arn" {
  description = "Existing Secrets Manager ARN for SMTP password"
  type        = string
  default     = ""
}
