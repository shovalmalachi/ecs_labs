variable "aws_region" {
  description = "AWS region used by the lab"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project prefix used for resource names"
  type        = string
  default     = "ecs-lab"
}

variable "repository_name" {
  description = "Name of the shared ECR repository"
  type        = string
  default     = "ecs-lab-shared-image"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ecs-lab-shared-image-cluster"
}

variable "image_tag" {
  description = "Shared image tag deployed by all services"
  type        = string
  default     = "v1"
}

variable "container_port" {
  description = "Application container port"
  type        = number
  default     = 3000
}

variable "api_desired_count" {
  description = "Desired task count for the API service"
  type        = number
  default     = 1
}

variable "jobs_desired_count" {
  description = "Desired task count for the jobs service"
  type        = number
  default     = 1
}

variable "events_desired_count" {
  description = "Desired task count for the events service"
  type        = number
  default     = 1
}

variable "cpu" {
  description = "Fargate CPU units for each task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate memory in MiB for each task"
  type        = number
  default     = 512
}