variable "service_name" {
  description = "Name of the ECS service and task definition family"
  type        = string
}

variable "container_name" {
  description = "Name of the ECS container"
  type        = string
}

variable "cluster_id" {
  description = "ID or ARN of the ECS cluster"
  type        = string
}

variable "image" {
  description = "Full container image URI including the tag"
  type        = string
}

variable "aws_region" {
  description = "AWS region used by CloudWatch logging"
  type        = string
}

variable "vpc_id" {
  description = "VPC in which the service security group is created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnets in which the ECS tasks are launched"
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
}

variable "desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
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

variable "assign_public_ip" {
  description = "Assign a public IP address to the ECS tasks"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the container port"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention period"
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Environment variables passed to the application container"
  type        = map(string)
  default     = {}
}