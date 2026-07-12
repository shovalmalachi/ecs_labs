variable "aws_region" {
  description = "AWS region in which the lab resources are created"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for tagging"
  type        = string
  default     = "ecs-lab"
}

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "ecs-lab-deploy-by-tag"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ecs-lab-deploy-by-tag-cluster"
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "ecs-lab-deploy-by-tag-service"
}

variable "container_name" {
  description = "Name of the container in the ECS task definition"
  type        = string
  default     = "ecs-lab-app"
}

variable "image_tag" {
  description = "Docker image tag deployed to ECS"
  type        = string
  default     = "v1"
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 3000
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count must be zero or greater."
  }
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 512
}