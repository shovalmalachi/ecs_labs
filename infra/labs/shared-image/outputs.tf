output "ecr_repository_url" {
  description = "URL of the shared ECR repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "Name of the shared ECR repository"
  value       = module.ecr.repository_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.cluster.cluster_name
}

output "service_names" {
  description = "Names of all ECS services"
  value = {
    api    = module.api_service.service_name
    jobs   = module.jobs_service.service_name
    events = module.events_service.service_name
  }
}

output "task_definition_arns" {
  description = "Task definition ARN for every service"
  value = {
    api    = module.api_service.task_definition_arn
    jobs   = module.jobs_service.task_definition_arn
    events = module.events_service.task_definition_arn
  }
}

output "log_group_names" {
  description = "CloudWatch log groups for all services"
  value = {
    api    = module.api_service.log_group_name
    jobs   = module.jobs_service.log_group_name
    events = module.events_service.log_group_name
  }
}

output "deployed_image" {
  description = "Shared image URI used by all services"
  value       = "${module.ecr.repository_url}:${var.image_tag}"
}