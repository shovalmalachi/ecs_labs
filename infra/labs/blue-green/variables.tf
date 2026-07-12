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
  default = "ecs-lab-blue-green"
}

variable "cluster_name" {
  type    = string
  default = "ecs-lab-blue-green-cluster"
}

variable "service_name" {
  type    = string
  default = "ecs-lab-blue-green-service"
}

variable "container_name" {
  type    = string
  default = "ecs-lab-app"
}

variable "alb_name" {
  type    = string
  default = "ecs-lab-bg-alb"
}

variable "codedeploy_name" {
  type    = string
  default = "ecs-lab-blue-green"
}

variable "image_tag" {
  type    = string
  default = "v1"
}

variable "container_port" {
  type    = number
  default = 3000
}