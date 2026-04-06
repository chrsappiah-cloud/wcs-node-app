output "alb_dns_name" {
  description = "Public DNS for backend ALB"
  value       = aws_lb.api.dns_name
}

output "backend_base_url" {
  description = "Backend base URL"
  value       = "http://${aws_lb.api.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.api.name
}

output "rds_endpoint" {
  description = "PostgreSQL endpoint"
  value       = aws_db_instance.postgres.address
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "middleware_queue_url" {
  description = "SQS middleware queue URL"
  value       = aws_sqs_queue.middleware.id
}

output "notifications_topic_arn" {
  description = "SNS topic ARN for backend notifications"
  value       = aws_sns_topic.notifications.arn
}

output "middleware_artifacts_bucket" {
  description = "S3 bucket for middleware artifacts"
  value       = aws_s3_bucket.middleware_artifacts.id
}

output "db_password_secret_arn" {
  description = "Secrets Manager ARN for database password"
  value       = local.db_password_secret_arn
  sensitive   = true
}

output "smtp_password_secret_arn" {
  description = "Secrets Manager ARN for SMTP password"
  value       = local.smtp_password_secret_arn
  sensitive   = true
}
