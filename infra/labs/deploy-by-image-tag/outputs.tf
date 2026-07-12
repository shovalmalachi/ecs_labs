output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = module.ecr.repository_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.cluster.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.cluster.cluster_arn
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = module.service.service_name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = module.service.task_definition_arn
}

output "log_group_name" {
  description = "CloudWatch log group used by the service"
  value       = module.service.log_group_name
}

output "container_port" {
  description = "Application container port"
  value       = var.container_port
}

output "deployed_image" {
  description = "Complete image URI deployed to ECS"
  value       = "${module.ecr.repository_url}:${var.image_tag}"
}