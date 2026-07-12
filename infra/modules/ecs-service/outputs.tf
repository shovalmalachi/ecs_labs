output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.this.name
}

output "service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Family of the ECS task definition"
  value       = aws_ecs_task_definition.this.family
}

output "security_group_id" {
  description = "Security group attached to the ECS tasks"
  value       = aws_security_group.this.id
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.this.name
}