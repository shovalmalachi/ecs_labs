variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "ecs-lab"
}

variable "repository_name" {
  type    = string
  default = "ecs-lab-new-service"
}

variable "cluster_name" {
  type    = string
  default = "ecs-lab-new-service-cluster"
}

variable "service_name" {
  type    = string
  default = "ecs-lab-new-service"
}

variable "container_name" {
  type    = string
  default = "ecs-lab-new-service"
}

variable "image_tag" {
  type    = string
  default = "v1"
}

variable "container_port" {
  type    = number
  default = 3000
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}