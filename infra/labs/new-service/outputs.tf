output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "ecr_repository_name" {
  value = module.ecr.repository_name
}

output "ecs_cluster_name" {
  value = module.cluster.cluster_name
}

output "ecs_service_name" {
  value = module.service.service_name
}

output "task_definition_arn" {
  value = module.service.task_definition_arn
}

output "log_group_name" {
  value = module.service.log_group_name
}