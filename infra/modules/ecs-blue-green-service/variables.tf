variable "service_name" {
  type = string
}

variable "container_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "image" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "blue_target_group_arn" {
  type = string
}

variable "production_listener_arn" {
  type = string
}

variable "container_port" {
  type = number
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