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

output "alb_url" {
  value = "http://${module.alb.alb_dns_name}"
}

output "codedeploy_application_name" {
  value = module.codedeploy.application_name
}

output "codedeploy_deployment_group_name" {
  value = module.codedeploy.deployment_group_name
}